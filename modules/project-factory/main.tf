/**
 * Module: project-factory
 * Hardened enterprise GCP project factory enforcing auditability, FinOps tagging and API enablement.
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

resource "google_project" "project" {
  name                = var.name
  project_id          = var.project_id
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = var.auto_create_network

  labels = var.labels
}

resource "google_project_service" "services" {
  for_each = toset(var.services)

  project = google_project.project.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}
