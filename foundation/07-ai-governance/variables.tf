/**
 * Phase 07: AI Governance - Variables
 */

variable "project_id" {
  description = "The GCP Project ID for the AI Governance template project."
  type        = string
  default     = "prj-prod-ai-governance-01"
}

variable "project_name" {
  description = "Display name of the AI Governance template project."
  type        = string
  default     = "AI Governance & Agent Platform Template"
}

variable "folder_id" {
  description = "Parent Folder ID where the AI project will be created (e.g., fldr-clinical-prod or fldr-banking-prod)."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID to associate with the AI project."
  type        = string
}

variable "primary_region" {
  description = "Primary GCP region for Vertex AI, Cloud KMS, and Cloud Storage resources."
  type        = string
  default     = "europe-west1"
}

variable "environment" {
  description = "Target environment tier (e.g., prod, non-prod, dev)."
  type        = string
  default     = "prod"
}

variable "cost_center" {
  description = "Cost Center code for FinOps allocation."
  type        = string
  default     = "cc-ai-agent-governance"
}

variable "business_unit" {
  description = "Business Unit responsible for the AI workload."
  type        = string
  default     = "ai-clinical-fintech"
}

variable "service_perimeter_name" {
  description = "The full resource name of the VPC Service Controls perimeter (e.g. accessPolicies/12345/servicePerimeters/sp_regulated_data_shield). If empty, project perimeter enrollment is skipped."
  type        = string
  default     = ""
}
