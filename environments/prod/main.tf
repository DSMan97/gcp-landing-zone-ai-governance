/**
 * Environment: Production
 * Provisions production workloads (Banking Core & Clinical Data Lake) with VPC-SC Perimeters and CMEK.
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
  region = var.primary_region
}

# 1. Standard Data Governance & FinOps Labels for Prod
module "prod_labels" {
  source = "../../modules/data-governance-labels"

  environment          = "prod"
  data_classification  = "confidential-pci-hipaa"
  regulated            = true
  cost_center          = "cc-banking-clinical-prod"
  business_unit        = "core-fintech-health"
  compliance_framework = "pci-dss-hipaa-gdpr"
}

# 2. Production Projects via Project Factory
module "prj_banking_prod" {
  source = "../../modules/project-factory"

  name            = "Banking Core Production"
  project_id      = "prj-prod-banking-core"
  folder_id       = var.banking_prod_folder_id
  billing_account = var.billing_account

  labels = module.prod_labels.labels

  services = [
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "bigquery.googleapis.com",
    "cloudkms.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "accesscontextmanager.googleapis.com"
  ]
}

module "prj_clinical_prod" {
  source = "../../modules/project-factory"

  name            = "Clinical Data Lake Production"
  project_id      = "prj-prod-clinical-data"
  folder_id       = var.clinical_prod_folder_id
  billing_account = var.billing_account

  labels = module.prod_labels.labels

  services = [
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "datacatalog.googleapis.com",
    "dlp.googleapis.com",
    "cloudkms.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

# 3. Dedicated KMS Keys for Prod CMEK
resource "google_kms_key_ring" "prod_keyring" {
  name     = "kr-prod-regulated-${var.primary_region}"
  location = var.primary_region
  project  = module.prj_banking_prod.project_id
}

resource "google_kms_crypto_key" "bq_key" {
  name            = "key-bq-clinical-banking-prod"
  key_ring        = google_kms_key_ring.prod_keyring.id
  rotation_period = "7776000s" # 90 days automatic rotation

  lifecycle {
    prevent_destroy = true
  }
}

# 4. VPC Service Controls (Security Perimeter) for Production (Enforced via Module)
resource "google_access_context_manager_access_policy" "policy" {
  parent = "organizations/${var.organization_id}"
  title  = "Enterprise Production Data Protection Policy"
}

resource "google_access_context_manager_access_level" "hq_trusted_network" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/al_hq_trusted_network"
  title  = "al_hq_trusted_network"

  basic {
    conditions {
      ip_subnetworks = [
        "198.51.100.0/24",
        "203.0.113.0/24"
      ]
    }
  }
}

module "prod_perimeter" {
  source = "../../modules/vpc-sc-perimeter"

  policy         = google_access_context_manager_access_policy.policy.name
  perimeter_name = "sp_regulated_data_shield"
  title          = "sp_regulated_data_shield"
  dry_run        = false

  restricted_services = [
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "aiplatform.googleapis.com"
  ]

  resources = [
    "projects/${module.prj_banking_prod.project_number}",
    "projects/${module.prj_clinical_prod.project_number}"
  ]

  access_levels = [
    google_access_context_manager_access_level.hq_trusted_network.name
  ]
}
