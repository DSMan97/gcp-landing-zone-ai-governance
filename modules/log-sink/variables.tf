/**
 * Module: log-sink - Variables
 */

variable "organization_id" {
  description = "Organization ID for org-level aggregated sink."
  type        = string
  default     = null
}

variable "destination_project_id" {
  description = "The security/audit project where logs are retained."
  type        = string
}

variable "sink_name" {
  description = "Name of the centralized audit log sink."
  type        = string
  default     = "sk-central-audit-compliance"
}

variable "dataset_id" {
  description = "BigQuery dataset ID to store compliance logs."
  type        = string
  default     = "ds_audit_compliance_logs"
}

variable "location" {
  description = "Location for the audit dataset."
  type        = string
  default     = "EU"
}

variable "create_dataset" {
  description = "Whether to create the destination BigQuery dataset."
  type        = bool
  default     = true
}

variable "custom_destination" {
  description = "Custom destination string if not creating dataset."
  type        = string
  default     = ""
}

variable "filter" {
  description = "Log filter for the sink. Defaults to capturing all audit logs and VPC flows."
  type        = string
  default     = "logName:\"logs/cloudaudit.googleapis.com\" OR logName:\"logs/compute.googleapis.com%2Fvpc_flows\""
}

variable "retention_days" {
  description = "Retention period for audit logs in days (e.g. 2555 days for 7-year banking compliance)."
  type        = number
  default     = 2555
}
