/**
 * Module: log-sink - Outputs
 */

output "sink_writer_identity" {
  description = "The identity created by GCP to write logs to the sink destination."
  value       = var.organization_id != null ? google_logging_organization_sink.org_sink[0].writer_identity : null
}

output "audit_dataset_id" {
  description = "The ID of the BigQuery Dataset containing the audit logs."
  value       = var.create_dataset ? google_bigquery_dataset.audit_dataset[0].id : null
}
