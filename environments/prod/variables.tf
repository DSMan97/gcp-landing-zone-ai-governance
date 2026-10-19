/**
 * Environment: Production - Variables
 */

variable "organization_id" {
  description = "The GCP Organization ID."
  type        = string
}

variable "billing_account" {
  description = "The billing account ID to associate with production projects."
  type        = string
}

variable "banking_prod_folder_id" {
  description = "Folder ID for banking production workloads."
  type        = string
}

variable "clinical_prod_folder_id" {
  description = "Folder ID for clinical production workloads."
  type        = string
}

variable "primary_region" {
  description = "Primary GCP region for prod deployment."
  type        = string
  default     = "europe-west1"
}
