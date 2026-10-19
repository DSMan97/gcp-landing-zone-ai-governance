/**
 * Module: cmek-kms - Outputs
 */

output "key_ring_id" {
  description = "The ID of the created KMS KeyRing."
  value       = google_kms_key_ring.keyring.id
}

output "key_ring_name" {
  description = "The name of the created KMS KeyRing."
  value       = google_kms_key_ring.keyring.name
}

output "crypto_key_id" {
  description = "The full ID of the created CMEK CryptoKey."
  value       = google_kms_crypto_key.crypto_key.id
}

output "crypto_key_name" {
  description = "The name of the created CMEK CryptoKey."
  value       = google_kms_crypto_key.crypto_key.name
}

output "service_agents" {
  description = "Map of created service agent identities and their emails."
  value       = { for k, v in google_project_service_identity.service_agents : k => v.email }
}
