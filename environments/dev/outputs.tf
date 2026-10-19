/**
 * Environment: Development (Dev) - Outputs
 */

output "banking_dev_project_id" {
  description = "The Banking Core Development Project ID."
  value       = module.prj_banking_dev.project_id
}

output "clinical_dev_project_id" {
  description = "The Clinical Data Lake Development Project ID."
  value       = module.prj_clinical_dev.project_id
}

output "vpc_sc_perimeter_id" {
  description = "The VPC Service Controls Perimeter resource name (Dry-Run mode)."
  value       = module.dev_perimeter.name
}

output "vpc_sc_perimeter_mode" {
  description = "The enforcement mode of the VPC-SC perimeter in Development."
  value       = "dry-run"
}
