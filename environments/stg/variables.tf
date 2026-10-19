/**
 * Environment: Staging (Stg) - Variables
 */

variable "organization_id" {
  description = "The GCP Organization ID for Access Context Manager policy."
  type        = string
}

variable "billing_account" {
  description = "The billing account ID to associate with staging projects."
  type        = string
}

variable "banking_stg_folder_id" {
  description = "Folder ID for banking staging workloads."
  type        = string
  default     = ""
}

variable "banking_non_prod_folder_id" {
  description = "Alternative Folder ID for banking non-production workloads (fallback)."
  type        = string
  default     = ""
}

variable "clinical_stg_folder_id" {
  description = "Folder ID for clinical staging workloads."
  type        = string
  default     = ""
}

variable "clinical_non_prod_folder_id" {
  description = "Alternative Folder ID for clinical non-production workloads (fallback)."
  type        = string
  default     = ""
}

variable "primary_region" {
  description = "Primary GCP region for staging deployment."
  type        = string
  default     = "europe-west1"
}
