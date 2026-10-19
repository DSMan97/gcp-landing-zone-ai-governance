/**
 * Module: data-governance-labels - Outputs
 */

output "labels" {
  description = "Standardized map of labels formatted for GCP resources."
  value       = local.merged_labels
}

output "environment" {
  description = "Validated environment identifier."
  value       = local.default_labels.environment
}

output "data_classification" {
  description = "Validated data classification level."
  value       = local.default_labels.data_classification
}
