/**
 * Module: custom-constraint
 * Provisions Organization Policy Custom Constraints using Common Expression Language (CEL).
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

resource "google_org_policy_custom_constraint" "constraints" {
  for_each = { for c in var.custom_constraints : c.name => c }

  name         = each.value.name
  parent       = "organizations/${var.organization_id}"
  display_name = each.value.display_name
  description  = each.value.description

  action_type    = each.value.action_type
  condition      = each.value.condition
  method_types   = each.value.method_types
  resource_types = each.value.resource_types
}
