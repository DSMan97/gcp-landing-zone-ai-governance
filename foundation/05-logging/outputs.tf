/**
 * Phase 05: Logging & Audit - Outputs
 */

output "sink_writer_identity" {
  description = "The service account identity writing logs to BigQuery."
  value       = module.central_log_sink.sink_writer_identity
}

output "audit_dataset_id" {
  description = "The BigQuery dataset ID storing compliance logs."
  value       = module.central_log_sink.audit_dataset_id
}

output "active_audit_services" {
  description = "List of services with data-access audit logging enabled."
  value       = module.audit_configs.configured_services
}
