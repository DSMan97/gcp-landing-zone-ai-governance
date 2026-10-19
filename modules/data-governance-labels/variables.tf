/**
 * Module: data-governance-labels - Variables
 */

variable "environment" {
  description = "Deployment environment (e.g., prod, non-prod, staging, stg, dev)."
  type        = string
  validation {
    condition     = contains(["prod", "non-prod", "staging", "stg", "dev"], var.environment)
    error_message = "Environment must be one of: prod, non-prod, staging, stg, dev."
  }
}

variable "data_classification" {
  description = "Data classification level (public, internal, confidential-pci-hipaa, restricted)."
  type        = string
  default     = "confidential-pci-hipaa"
}

variable "regulated" {
  description = "Flag indicating if the resource hosts regulated data."
  type        = bool
  default     = true
}

variable "cost_center" {
  description = "FinOps cost center identifier."
  type        = string
  default     = "cc-core-platform"
}

variable "business_unit" {
  description = "Business Unit responsible for the resource."
  type        = string
  default     = "digital-banking-clinical"
}

variable "compliance_framework" {
  description = "Primary compliance framework (pci-dss-hipaa-gdpr, iso27001, standard)."
  type        = string
  default     = "pci-dss-hipaa-gdpr"
}

variable "additional_labels" {
  description = "Additional custom labels to merge."
  type        = map(string)
  default     = {}
}
