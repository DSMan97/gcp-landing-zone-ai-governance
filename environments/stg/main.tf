/**
 * Environment: Staging (Stg)
 * Provisions pre-production workloads (Banking Core & Clinical Data Lake)
 * with dedicated CMEK, staging governance labels, and VPC-SC perimeter for pre-prod validation.
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

# 1. Standard Data Governance & FinOps Labels for Staging
module "stg_labels" {
  source = "../../modules/data-governance-labels"

  environment          = "stg"
  data_classification  = "confidential-simulated"
  regulated            = true
  cost_center          = "cc-banking-clinical-stg"
  business_unit        = "core-fintech-health"
  compliance_framework = "pci-dss-hipaa-gdpr-stg"
}

# 2. Staging Projects via Project Factory
locals {
  banking_folder_id  = var.banking_stg_folder_id != "" ? var.banking_stg_folder_id : var.banking_non_prod_folder_id
  clinical_folder_id = var.clinical_stg_folder_id != "" ? var.clinical_stg_folder_id : var.clinical_non_prod_folder_id
}

module "prj_banking_stg" {
  source = "../../modules/project-factory"

  name            = "Banking Core Staging"
  project_id      = "prj-stg-banking-core"
  folder_id       = local.banking_folder_id
  billing_account = var.billing_account

  labels = module.stg_labels.labels

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

module "prj_clinical_stg" {
  source = "../../modules/project-factory"

  name            = "Clinical Data Lake Staging"
  project_id      = "prj-stg-clinical-data"
  folder_id       = local.clinical_folder_id
  billing_account = var.billing_account

  labels = module.stg_labels.labels

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

# 3. Dedicated KMS Keys for Staging CMEK Validation
resource "google_kms_key_ring" "stg_keyring" {
  name     = "kr-stg-regulated-${var.primary_region}"
  location = var.primary_region
  project  = module.prj_banking_stg.project_id
}

resource "google_kms_crypto_key" "bq_key" {
  name            = "key-bq-clinical-banking-stg"
  key_ring        = google_kms_key_ring.stg_keyring.id
  rotation_period = "7776000s" # 90 days automatic rotation

  lifecycle {
    prevent_destroy = false # Permitted for staging teardown & rebuild cycles
  }
}

# 4. VPC Service Controls - Staging Security Perimeter (Enforced via Module)
resource "google_access_context_manager_access_policy" "stg_policy" {
  parent = "organizations/${var.organization_id}"
  title  = "Enterprise Staging Data Protection Policy"
}

resource "google_access_context_manager_access_level" "stg_trusted_network" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.stg_policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.stg_policy.name}/accessLevels/al_stg_trusted_network"
  title  = "al_stg_trusted_network"

  basic {
    conditions {
      ip_subnetworks = [
        "198.51.100.0/24",
        "203.0.113.0/24"
      ]
    }
  }
}

module "stg_perimeter" {
  source = "../../modules/vpc-sc-perimeter"

  policy         = google_access_context_manager_access_policy.stg_policy.name
  perimeter_name = "sp_stg_data_shield"
  title          = "sp_stg_data_shield"
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
    "projects/${module.prj_banking_stg.project_number}",
    "projects/${module.prj_clinical_stg.project_number}"
  ]

  access_levels = [
    google_access_context_manager_access_level.stg_trusted_network.name
  ]
}
