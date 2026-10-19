/**
 * Phase: Bootstrap - Outputs
 */

output "tfstate_buckets" {
  description = "Map of state buckets created for each landing zone stage."
  value       = { for k, v in google_storage_bucket.tfstate_buckets : k => v.name }
}

output "state_kms_key_id" {
  description = "The Cloud KMS CryptoKey ID used for CMEK state encryption."
  value       = google_kms_crypto_key.state_key.id
}

output "terraform_service_accounts" {
  description = "Map of Terraform Service Accounts provisioned."
  value       = { for k, v in google_service_account.terraform_sa : k => v.email }
}

output "wif_pool_name" {
  description = "The Workload Identity Pool name."
  value       = google_iam_workload_identity_pool.github_pool.name
}

output "wif_provider_name" {
  description = "The Workload Identity Provider resource name."
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}
