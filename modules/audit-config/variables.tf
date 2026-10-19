/**
 * Module: audit-config - Variables
 */

variable "organization_id" {
  description = "Organization ID to configure audit logs for."
  type        = string
  default     = null
}

variable "services" {
  description = "List of GCP services to enable audit logging for."
  type        = list(string)
  default = [
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
}

variable "audit_log_types" {
  description = "List of log types to collect (ADMIN_READ, DATA_READ, DATA_WRITE)."
  type        = list(string)
  default     = ["ADMIN_READ", "DATA_READ", "DATA_WRITE"]
}

variable "exempted_members_by_type" {
  description = "Map of log types to list of exempted members."
  type        = map(list(string))
  default     = {}
}
