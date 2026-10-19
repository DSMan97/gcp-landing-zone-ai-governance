/**
 * Phase 07: AI Governance - Outputs
 */

output "project_id" {
  description = "The AI Governance Template Project ID."
  value       = module.ai_workload_template.project_id
}

output "project_number" {
  description = "The AI Governance Template Project Number."
  value       = module.ai_workload_template.project_number
}

output "cmek_keyring_id" {
  description = "The ID of the Cloud KMS KeyRing dedicated to AI workloads."
  value       = module.ai_workload_template.cmek_keyring_id
}

output "cmek_crypto_key_id" {
  description = "The ID of the CMEK CryptoKey for Vertex AI, GCS, and Artifact Registry."
  value       = module.ai_workload_template.cmek_crypto_key_id
}

output "ai_data_bucket_name" {
  description = "The name of the CMEK-encrypted Cloud Storage data lake bucket."
  value       = module.ai_workload_template.ai_data_bucket_name
}

output "ai_data_bucket_url" {
  description = "The gs:// URI of the AI data lake bucket."
  value       = module.ai_workload_template.ai_data_bucket_url
}

output "artifact_registry_repository_id" {
  description = "The ID of the Artifact Registry repository for AI containers."
  value       = module.ai_workload_template.artifact_registry_repository_id
}

output "vertex_tensorboard_id" {
  description = "The ID of the Vertex AI Tensorboard instance."
  value       = module.ai_workload_template.vertex_tensorboard_id
}

output "vertex_endpoint_id" {
  description = "The ID of the Vertex AI demonstration endpoint."
  value       = module.ai_workload_template.vertex_endpoint_id
}
