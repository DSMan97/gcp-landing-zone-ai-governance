/**
 * Phase 04: IAM - Variables
 */

variable "prod_folder_id" {
  description = "The target Production Folder ID."
  type        = string
}

variable "customer_id" {
  description = "Google Workspace / Cloud Identity Customer ID (e.g. C01234567)."
  type        = string
  default     = null
}

variable "admin_user_email" {
  description = "Super admin / delegated user email for Google Workspace impersonation."
  type        = string
  default     = null
}

variable "manage_workspace_groups" {
  description = "Whether to create and manage the security groups in Google Workspace."
  type        = bool
  default     = true
}

variable "service_account_project_id" {
  description = "The GCP Project ID where dedicated workload service accounts are provisioned."
  type        = string
  default     = null
}

variable "legal_team_group" {
  description = "Google Group email for Legal & Compliance department."
  type        = string
  default     = "gcp-legal-compliance@bank-clinical-enterprise.com"
}

variable "soc_team_group" {
  description = "Google Group email for Security Operations Center."
  type        = string
  default     = "gcp-soc-secops@bank-clinical-enterprise.com"
}

variable "break_glass_group" {
  description = "Google Group email for Emergency Break-Glass administrators."
  type        = string
  default     = "gcp-breakglass-admins@bank-clinical-enterprise.com"
}

variable "data_scientists_group" {
  description = "Google Group email for Data Scientists and AI Researchers."
  type        = string
  default     = "gcp-data-scientists@bank-clinical-enterprise.com"
}

variable "agent_deployers_group" {
  description = "Google Group email for AI Agent Platform Deployers and MLOps Engineers."
  type        = string
  default     = "gcp-agent-deployers@bank-clinical-enterprise.com"
}

variable "ai_auditors_group" {
  description = "Google Group email for AI Compliance and Governance Auditors."
  type        = string
  default     = "gcp-ai-auditors@bank-clinical-enterprise.com"
}
