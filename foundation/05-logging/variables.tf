/**
 * Phase 05: Logging & Audit - Variables
 */

variable "organization_id" {
  description = "The GCP Organization ID."
  type        = string
}

variable "audit_logs_project_id" {
  description = "The GCP Project ID dedicated to security audit logs storage."
  type        = string
}
