/**
 * Module: project-factory - Outputs
 */

output "project_id" {
  description = "The resulting Project ID."
  value       = google_project.project.project_id
}

output "project_number" {
  description = "The resulting Project Number."
  value       = google_project.project.number
}
