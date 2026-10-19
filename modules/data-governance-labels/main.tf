/**
 * Module: data-governance-labels
 * Computes, validates and outputs standard data governance, FinOps, and compliance labels.
 */

terraform {
  required_version = ">= 1.5.0"
}

locals {
  # Standardized base labels
  default_labels = {
    environment          = lower(var.environment)
    data_classification  = lower(var.data_classification)
    regulated            = var.regulated ? "true" : "false"
    cost_center          = lower(var.cost_center)
    business_unit        = lower(var.business_unit)
    managed_by           = "terraform"
    compliance_framework = lower(var.compliance_framework)
  }

  merged_labels = merge(local.default_labels, var.additional_labels)
}
