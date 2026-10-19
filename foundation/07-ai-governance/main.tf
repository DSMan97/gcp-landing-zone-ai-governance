/**
 * Phase 07: AI Governance - AI Project Template
 * Provisions an enterprise-grade AI template project enclosed within the VPC Service Controls perimeter,
 * equipped with CMEK encryption via Cloud KMS, secure Cloud Storage data lake, and baseline demonstration AI resources
 * using the reusable ai-workload-project module.
 */

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0.0"
    }
  }
}

# AI Template Project using Reusable AI Workload Factory Module
module "ai_workload_template" {
  source = "../../modules/ai-workload-project"

  project_id      = var.project_id
  project_name    = var.project_name
  folder_id       = var.folder_id
  billing_account = var.billing_account
  primary_region  = var.primary_region
  environment     = var.environment

  cost_center          = var.cost_center
  business_unit        = var.business_unit
  data_classification  = "confidential-pci-hipaa"
  compliance_framework = "nist-ai-rmf-iso-42001-pci-hipaa"
  regulated            = true

  create_cmek              = true
  create_storage_bucket    = true
  create_artifact_registry = true
  create_tensorboard       = true
  create_endpoint          = true

  service_perimeter_name = var.service_perimeter_name
}
