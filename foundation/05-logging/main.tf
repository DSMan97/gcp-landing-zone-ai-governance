/**
 * Phase 05: Logging & Audit - Centralized Compliance Ingestion
 * Provisions org-level aggregated sink to BigQuery with 7-year retention and full IAM audit configs.
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

# 1. Organization Aggregated Log Sink to BigQuery
module "central_log_sink" {
  source = "../../modules/log-sink"

  organization_id        = var.organization_id
  destination_project_id = var.audit_logs_project_id
  sink_name              = "sk-central-audit-compliance"
  dataset_id             = "ds_audit_compliance_logs"
  location               = "EU"
  create_dataset         = true
  retention_days         = 2555 # 7 years regulatory retention

  filter = "logName:\"logs/cloudaudit.googleapis.com\" OR logName:\"logs/compute.googleapis.com%2Fvpc_flows\" OR logName:\"logs/dns.googleapis.com%2Fdns_queries\""
}

# 2. Organization IAM Audit Configs (DATA_READ, DATA_WRITE, ADMIN_READ)
module "audit_configs" {
  source = "../../modules/audit-config"

  organization_id = var.organization_id

  services = [
    "allServices",
    "aiplatform.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "cloudsql.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "securitycenter.googleapis.com",
    "accessapproval.googleapis.com"
  ]

  audit_log_types = [
    "ADMIN_READ",
    "DATA_READ",
    "DATA_WRITE"
  ]
}
