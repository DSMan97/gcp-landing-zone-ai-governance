/**
 * Phase 00: Organization - Outputs
 */

output "organization_id" {
  description = "The GCP Organization ID configured."
  value       = var.organization_id
}

output "contacts" {
  description = "List of configured essential contacts."
  value = [
    google_essential_contacts_contact.security_contact.name,
    google_essential_contacts_contact.legal_contact.name,
    google_essential_contacts_contact.billing_contact.name
  ]
}

output "scc_notification_config_name" {
  description = "Security Command Center organization notification config resource name."
  value       = var.enable_scc_notifications ? google_scc_notification_config.scc_org_notification[0].name : null
}

output "access_approval_settings_id" {
  description = "Access Approval / Transparency organization settings resource ID."
  value       = var.enable_access_approval ? google_organization_access_approval_settings.org_access_approval[0].id : null
}
