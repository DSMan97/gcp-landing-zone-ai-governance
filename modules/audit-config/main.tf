/**
 * Module: audit-config
 * Configures Organization/Folder/Project-level Audit Logs (DATA_READ, DATA_WRITE, ADMIN_READ).
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

resource "google_organization_iam_audit_config" "org_audit_configs" {
  for_each = var.organization_id != null ? toset(var.services) : []

  org_id  = var.organization_id
  service = each.value

  dynamic "audit_log_config" {
    for_each = var.audit_log_types
    content {
      log_type         = audit_log_config.value
      exempted_members = lookup(var.exempted_members_by_type, audit_log_config.value, [])
    }
  }
}
