/**
 * Module: audit-config - Outputs
 */

output "configured_services" {
  description = "List of services with audit configs active."
  value       = keys(google_organization_iam_audit_config.org_audit_configs)
}
