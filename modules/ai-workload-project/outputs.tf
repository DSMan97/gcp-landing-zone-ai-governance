/**
 * Module: ai-workload-project - Outputs
 */

output "project_id" {
  description = "The resulting AI Workload Project ID."
  value       = module.project.project_id
}

output "project_number" {
  description = "The resulting AI Workload Project Number."
  value       = module.project.project_number
}

output "cmek_keyring_id" {
  description = "The ID of the Cloud KMS KeyRing dedicated to the AI workload."
  value       = var.create_cmek ? module.cmek[0].key_ring_id : null
}

output "cmek_crypto_key_id" {
  description = "The ID of the CMEK CryptoKey for Vertex AI, GCS, and Artifact Registry."
  value       = local.cmek_key_id
}

output "ai_data_bucket_name" {
  description = "The name of the CMEK-encrypted Cloud Storage data lake bucket."
  value       = var.create_storage_bucket ? google_storage_bucket.ai_data_bucket[0].name : null
}

output "ai_data_bucket_url" {
  description = "The gs:// URI of the AI data lake bucket."
  value       = var.create_storage_bucket ? google_storage_bucket.ai_data_bucket[0].url : null
}

output "artifact_registry_repository_id" {
  description = "The ID of the Artifact Registry repository for AI containers."
  value       = var.create_artifact_registry ? google_artifact_registry_repository.ai_models_repo[0].id : null
}

output "vertex_tensorboard_id" {
  description = "The ID of the Vertex AI Tensorboard instance."
  value       = var.create_tensorboard ? google_vertex_ai_tensorboard.tensorboard[0].id : null
}

output "vertex_endpoint_id" {
  description = "The ID of the Vertex AI inference endpoint."
  value       = var.create_endpoint ? google_vertex_ai_endpoint.endpoint[0].id : null
}

output "labels" {
  description = "Data governance and compliance labels applied to all resources."
  value       = module.labels.labels
}
