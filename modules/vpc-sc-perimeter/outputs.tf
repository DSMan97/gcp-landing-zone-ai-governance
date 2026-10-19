/**
 * Module: vpc-sc-perimeter
 * Outputs definition for VPC Service Controls Service Perimeter.
 */

output "id" {
  description = "The fully-qualified identifier of the VPC Service Controls service perimeter."
  value       = google_access_context_manager_service_perimeter.perimeter.id
}

output "name" {
  description = "The resource name of the VPC Service Controls service perimeter."
  value       = google_access_context_manager_service_perimeter.perimeter.name
}

output "title" {
  description = "The title of the VPC Service Controls service perimeter."
  value       = google_access_context_manager_service_perimeter.perimeter.title
}

output "perimeter_type" {
  description = "The type of the service perimeter (REGULAR or BRIDGE)."
  value       = google_access_context_manager_service_perimeter.perimeter.perimeter_type
}

output "dry_run" {
  description = "Whether the perimeter is configured in dry-run mode."
  value       = var.dry_run
}
