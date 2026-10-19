/**
 * Phase: Bootstrap - Main Orchestration
 * Provisions segregated state buckets with CMEK, dedicated Service Accounts, and Workload Identity Federation.
 */

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.bootstrap_project_id
  region  = var.primary_region
}

# 1. Cloud KMS Key Ring & Crypto Key for CMEK State Encryption
resource "google_kms_key_ring" "state_keyring" {
  name     = "kr-tfstate-${var.primary_region}"
  location = var.primary_region
  project  = var.bootstrap_project_id
}

resource "google_kms_crypto_key" "state_key" {
  name            = "key-tfstate-cmek"
  key_ring        = google_kms_key_ring.state_keyring.id
  rotation_period = "7776000s" # 90 days automatic rotation

  lifecycle {
    prevent_destroy = true
  }
}

# Grant GCS service agent encrypter/decrypter permissions on the CMEK key
data "google_storage_project_service_account" "gcs_account" {
  project = var.bootstrap_project_id
}

resource "google_kms_crypto_key_iam_member" "gcs_cmek_binding" {
  crypto_key_id = google_kms_crypto_key.state_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# 2. Access Logging Bucket for Terraform State Auditing
resource "google_storage_bucket" "state_access_logs" {
  name                        = "bkt-tfstate-access-logs-${var.bootstrap_project_id}"
  location                    = var.primary_region
  project                     = var.bootstrap_project_id
  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 2555 # 7 years retention for banking & clinical audit compliance
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment         = "bootstrap"
    data_classification = "confidential-pci-hipaa"
    regulated           = "true"
    purpose             = "state-access-logs"
  }
}

# 3. Segregated State Buckets for each Landing Zone phase
locals {
  stages = [
    "bootstrap",
    "foundation-organization",
    "foundation-folders",
    "foundation-org-policies",
    "foundation-custom-constraints",
    "foundation-iam",
    "foundation-logging",
    "foundation-networking",
    "env-prod",
    "env-non-prod"
  ]
}

resource "google_storage_bucket" "tfstate_buckets" {
  for_each = toset(local.stages)

  name                        = "bkt-tfstate-${each.key}-${var.bootstrap_project_id}"
  location                    = var.primary_region
  project                     = var.bootstrap_project_id
  force_destroy               = false
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.state_key.id
  }

  logging {
    log_bucket        = google_storage_bucket.state_access_logs.name
    log_object_prefix = "${each.key}/"
  }

  labels = {
    environment         = "bootstrap"
    stage               = each.key
    data_classification = "confidential-pci-hipaa"
    regulated           = "true"
    managed_by          = "terraform"
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_cmek_binding]
}

# 4. Domain-Segregated Terraform Service Accounts (Least Privilege)
locals {
  service_accounts = {
    "sa-tf-bootstrap"  = "Terraform SA for Bootstrap and CI/CD State management"
    "sa-tf-foundation" = "Terraform SA for Organization Foundation, Policies, IAM, and Networking"
    "sa-tf-security"   = "Terraform SA for Security Perimeters, KMS, and Compliance Logging"
    "sa-tf-workload"   = "Terraform SA for Project Factory and Workload Deployments"
  }
}

resource "google_service_account" "terraform_sa" {
  for_each = local.service_accounts

  account_id   = each.key
  display_name = each.value
  project      = var.bootstrap_project_id
}

# 5. Workload Identity Federation (WIF) for Keyless CI/CD
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "pool-github-actions"
  project                   = var.bootstrap_project_id
  display_name              = "GitHub Actions Workload Identity Pool"
  description               = "Identity pool for keyless GitHub Actions CI/CD pipelines"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "provider-github"
  project                            = var.bootstrap_project_id
  display_name                       = "GitHub OIDC Provider"
  description                        = "OIDC identity provider for GitHub repository"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Bind CI/CD repo to Terraform SAs via WIF (no static keys)
resource "google_service_account_iam_member" "wif_sa_bindings" {
  for_each = local.service_accounts

  service_account_id = google_service_account.terraform_sa[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repository}"
}
