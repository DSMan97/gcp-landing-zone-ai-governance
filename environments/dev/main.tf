/**
 * Environment: Development (Dev)
 * Provisions isolated development workloads (Banking Core & Clinical Data Lake)
 * with Dry-Run VPC Service Controls perimeter and development governance labels.
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

# 1. Data Governance & FinOps Labels for Development
module "dev_labels" {
  source = "../../modules/data-governance-labels"

  environment          = "dev"
  data_classification  = "internal"
  regulated            = false
  cost_center          = "cc-banking-clinical-dev"
  business_unit        = "core-fintech-health"
  compliance_framework = "internal-dev"
}

# 2. Development Projects via Project Factory
locals {
  banking_folder_id  = var.banking_dev_folder_id != "" ? var.banking_dev_folder_id : var.banking_non_prod_folder_id
  clinical_folder_id = var.clinical_dev_folder_id != "" ? var.clinical_dev_folder_id : var.clinical_non_prod_folder_id
}

module "prj_banking_dev" {
  source = "../../modules/project-factory"

  name            = "Banking Core Development"
  project_id      = "prj-dev-banking-core"
  folder_id       = local.banking_folder_id
  billing_account = var.billing_account

  labels = module.dev_labels.labels

  services = [
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "bigquery.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "accesscontextmanager.googleapis.com"
  ]
}

module "prj_clinical_dev" {
  source = "../../modules/project-factory"

  name            = "Clinical Data Lake Development"
  project_id      = "prj-dev-clinical-data"
  folder_id       = local.clinical_folder_id
  billing_account = var.billing_account

  labels = module.dev_labels.labels

  services = [
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

# 3. VPC Service Controls - Development Security Perimeter (Dry-Run Mode via Module)
# In development, the perimeter runs with explicit dry-run spec to log violations without blocking developers
resource "google_access_context_manager_access_policy" "dev_policy" {
  parent = "organizations/${var.organization_id}"
  title  = "Enterprise Development Data Protection Policy"
}

resource "google_access_context_manager_access_level" "dev_trusted_network" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.dev_policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.dev_policy.name}/accessLevels/al_dev_trusted_network"
  title  = "al_dev_trusted_network"

  basic {
    conditions {
      ip_subnetworks = [
        "198.51.100.0/24",
        "203.0.113.0/24"
      ]
    }
  }
}

module "dev_perimeter" {
  source = "../../modules/vpc-sc-perimeter"

  policy         = google_access_context_manager_access_policy.dev_policy.name
  perimeter_name = "sp_dev_data_shield"
  title          = "sp_dev_data_shield"
  dry_run        = true

  restricted_services = [
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "aiplatform.googleapis.com"
  ]

  resources = [
    "projects/${module.prj_banking_dev.project_number}",
    "projects/${module.prj_clinical_dev.project_number}"
  ]

  access_levels = [
    google_access_context_manager_access_level.dev_trusted_network.name
  ]
}
