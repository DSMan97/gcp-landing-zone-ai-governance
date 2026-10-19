/**
 * Phase 01: Folders - Organizational Resource Hierarchy
 * Creates isolated folder tree for segregation of duties between banking, clinical, and shared platforms.
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

# Top-level Root Folders
resource "google_folder" "common" {
  display_name = "fldr-common"
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "production" {
  display_name = "fldr-production"
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "non_production" {
  display_name = "fldr-non-production"
  parent       = "organizations/${var.organization_id}"
}

resource "google_folder" "sandbox" {
  display_name = "fldr-sandbox"
  parent       = "organizations/${var.organization_id}"
}

# Sub-folders: Common Infrastructure
resource "google_folder" "bootstrap" {
  display_name = "fldr-bootstrap"
  parent       = google_folder.common.name
}

resource "google_folder" "security" {
  display_name = "fldr-security-governance"
  parent       = google_folder.common.name
}

resource "google_folder" "networking" {
  display_name = "fldr-networking-hub"
  parent       = google_folder.common.name
}

# Sub-folders: Production Segregation
resource "google_folder" "banking_prod" {
  display_name = "fldr-banking-prod"
  parent       = google_folder.production.name
}

resource "google_folder" "clinical_prod" {
  display_name = "fldr-clinical-prod"
  parent       = google_folder.production.name
}

# Sub-folders: Non-Production Segregation
resource "google_folder" "banking_non_prod" {
  display_name = "fldr-banking-non-prod"
  parent       = google_folder.non_production.name
}

resource "google_folder" "clinical_non_prod" {
  display_name = "fldr-clinical-non-prod"
  parent       = google_folder.non_production.name
}

# Sub-folders: Staging Environment Segregation
resource "google_folder" "banking_stg" {
  display_name = "fldr-banking-stg"
  parent       = google_folder.non_production.name
}

resource "google_folder" "clinical_stg" {
  display_name = "fldr-clinical-stg"
  parent       = google_folder.non_production.name
}
