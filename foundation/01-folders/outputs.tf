/**
 * Phase 01: Folders - Outputs
 */

output "folder_ids" {
  description = "Map of all created folder IDs."
  value = {
    common            = google_folder.common.name
    production        = google_folder.production.name
    non_production    = google_folder.non_production.name
    sandbox           = google_folder.sandbox.name
    bootstrap         = google_folder.bootstrap.name
    security          = google_folder.security.name
    networking        = google_folder.networking.name
    banking_prod      = google_folder.banking_prod.name
    clinical_prod     = google_folder.clinical_prod.name
    banking_non_prod  = google_folder.banking_non_prod.name
    clinical_non_prod = google_folder.clinical_non_prod.name
    banking_stg       = google_folder.banking_stg.name
    clinical_stg      = google_folder.clinical_stg.name
  }
}
