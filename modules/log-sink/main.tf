/**
 * Module: log-sink
 * Provisions centralized Organization / Folder aggregated Log Sinks to BigQuery or Cloud Storage.
 */

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

# BigQuery Dataset destination for audit logs
resource "google_bigquery_dataset" "audit_dataset" {
  count                      = var.create_dataset ? 1 : 0
  project                    = var.destination_project_id
  dataset_id                 = var.dataset_id
  friendly_name              = "Centralized Immutable Audit Logs"
  description                = "Aggregated organization audit and VPC flow logs for banking and clinical compliance."
  location                   = var.location
  delete_contents_on_destroy = false

  default_table_expiration_ms = var.retention_days * 24 * 60 * 60 * 1000
}

# Aggregated Organization Log Sink
resource "google_logging_organization_sink" "org_sink" {
  count            = var.organization_id != null ? 1 : 0
  name             = var.sink_name
  org_id           = var.organization_id
  destination      = var.create_dataset ? "bigquery.googleapis.com/${google_bigquery_dataset.audit_dataset[0].id}" : var.custom_destination
  filter           = var.filter
  include_children = true
}

# BigQuery Dataset Access Binding for Org Sink Writer
resource "google_bigquery_dataset_iam_member" "sink_writer_dataset_editor" {
  count      = (var.organization_id != null && var.create_dataset) ? 1 : 0
  project    = var.destination_project_id
  dataset_id = google_bigquery_dataset.audit_dataset[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_organization_sink.org_sink[0].writer_identity
}
