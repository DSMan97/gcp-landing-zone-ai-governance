/**
 * Phase 07: AI Governance - Outputs
 */

output "project_id" {
  description = "The AI Governance Template Project ID."
  value       = module.ai_project.project_id
}

output "project_number" {
  description = "The AI Governance Template Project Number."
  value       = module.ai_project.project_number
}

output "cmek_keyring_id" {
  description = "The ID of the Cloud KMS KeyRing dedicated to AI workloads."
  value       = google_kms_key_ring.ai_keyring.id
}

output "cmek_crypto_key_id" {
  description = "The ID of the CMEK CryptoKey for Vertex AI, GCS, and Artifact Registry."
  value       = google_kms_crypto_key.ai_cmek_key.id
}

output "ai_data_bucket_name" {
  description = "The name of the CMEK-encrypted Cloud Storage data lake bucket."
  value       = google_storage_bucket.ai_data_bucket.name
}

output "ai_data_bucket_url" {
  description = "The gs:// URI of the AI data lake bucket."
  value       = google_storage_bucket.ai_data_bucket.url
}

output "artifact_registry_repository_id" {
  description = "The ID of the Artifact Registry repository for AI containers."
  value       = google_artifact_registry_repository.ai_models_repo.id
}

output "vertex_tensorboard_id" {
  description = "The ID of the Vertex AI Tensorboard instance."
  value       = google_vertex_ai_tensorboard.demo_tensorboard.id
}

output "vertex_endpoint_id" {
  description = "The ID of the Vertex AI demonstration endpoint."
  value       = google_vertex_ai_endpoint.demo_endpoint.id
}
