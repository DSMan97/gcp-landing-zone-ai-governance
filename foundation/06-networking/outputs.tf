/**
 * Phase 06: Networking - Outputs
 */

output "shared_vpc_id" {
  description = "The ID of the Shared VPC Network."
  value       = google_compute_network.shared_vpc.id
}

output "shared_vpc_name" {
  description = "The name of the Shared VPC Network."
  value       = google_compute_network.shared_vpc.name
}

output "banking_subnet_id" {
  description = "The ID of the Banking production subnet."
  value       = google_compute_subnetwork.sb_banking_prod.id
}

output "clinical_subnet_id" {
  description = "The ID of the Clinical production subnet."
  value       = google_compute_subnetwork.sb_clinical_prod.id
}

output "psc_endpoint_ip" {
  description = "The reserved internal IP address for Private Service Connect."
  value       = google_compute_global_address.psc_google_apis.address
}

output "psc_forwarding_rule_id" {
  description = "The ID of the Private Service Connect global forwarding rule."
  value       = google_compute_global_forwarding_rule.psc_google_apis.id
}

output "access_policy_id" {
  description = "The ID/Name of the Access Context Manager policy."
  value       = google_access_context_manager_access_policy.policy.name
}

output "access_level_name" {
  description = "The name of the Access Level for trusted corporate networks."
  value       = google_access_context_manager_access_level.hq_trusted_network.name
}

output "service_perimeter_name" {
  description = "The name of the VPC Service Controls service perimeter."
  value       = module.service_perimeter.title
}

output "restricted_services" {
  description = "List of Google Cloud and AI services protected by the VPC-SC perimeter."
  value       = var.restricted_services
}
