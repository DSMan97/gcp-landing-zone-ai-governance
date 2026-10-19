/**
 * Environment: Production - Outputs
 */

output "banking_prod_project_id" {
  description = "The Banking Core Production Project ID."
  value       = module.prj_banking_prod.project_id
}

output "clinical_prod_project_id" {
  description = "The Clinical Data Lake Production Project ID."
  value       = module.prj_clinical_prod.project_id
}

output "vpc_sc_perimeter_id" {
  description = "The VPC Service Controls Perimeter resource name (Enforced mode)."
  value       = module.prod_perimeter.name
}

output "vpc_sc_perimeter_mode" {
  description = "The enforcement mode of the VPC-SC perimeter in Production."
  value       = "enforced"
}

output "prod_cmek_key_id" {
  description = "Central CMEK Key ID for BigQuery/GCS in production."
  value       = google_kms_crypto_key.bq_key.id
}
