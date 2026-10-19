/**
 * Environment: Staging (Stg) - Outputs
 */

output "banking_stg_project_id" {
  description = "The Banking Core Staging Project ID."
  value       = module.prj_banking_stg.project_id
}

output "clinical_stg_project_id" {
  description = "The Clinical Data Lake Staging Project ID."
  value       = module.prj_clinical_stg.project_id
}

output "vpc_sc_perimeter_id" {
  description = "The VPC Service Controls Perimeter resource name (Staging)."
  value       = module.stg_perimeter.name
}

output "vpc_sc_perimeter_mode" {
  description = "The enforcement mode of the VPC-SC perimeter in Staging."
  value       = "enforced"
}

output "stg_cmek_key_id" {
  description = "Central CMEK Key ID for BigQuery/GCS in staging."
  value       = google_kms_crypto_key.bq_key.id
}
