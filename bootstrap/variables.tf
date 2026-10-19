/**
 * Phase: Bootstrap - Variables
 */

variable "bootstrap_project_id" {
  description = "The GCP Project ID where bootstrap resources reside."
  type        = string
}

variable "primary_region" {
  description = "The primary GCP region for state buckets and KMS."
  type        = string
  default     = "europe-west1"
}

variable "github_repository" {
  description = "The GitHub repository authorized for WIF (e.g. organization/repo)."
  type        = string
  default     = "enterprise-org/gcp-landing-zone"
}

variable "organization_id" {
  description = "The GCP Organization ID."
  type        = string
}
