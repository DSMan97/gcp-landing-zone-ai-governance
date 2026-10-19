/**
 * Phase 00: Organization - Variables
 */

variable "organization_id" {
  description = "The GCP Organization ID."
  type        = string
}

variable "security_team_email" {
  description = "Email address for SOC / SecOps team."
  type        = string
  default     = "secops@bank-clinical-enterprise.com"
}

variable "legal_team_email" {
  description = "Email address for Legal / Compliance team."
  type        = string
  default     = "compliance-legal@bank-clinical-enterprise.com"
}

variable "billing_team_email" {
  description = "Email address for FinOps / Billing department."
  type        = string
  default     = "finops@bank-clinical-enterprise.com"
}

variable "scc_notification_pubsub_topic" {
  description = "Pub/Sub topic ID for Security Command Center finding notifications."
  type        = string
  default     = "projects/prj-sec-monitoring/topics/top-scc-findings"
}

variable "enable_scc_notifications" {
  description = "Whether to enable organization-level Security Command Center notification config."
  type        = bool
  default     = true
}

variable "enable_access_approval" {
  description = "Whether to enable organization-level Access Approval / Transparency settings."
  type        = bool
  default     = true
}
