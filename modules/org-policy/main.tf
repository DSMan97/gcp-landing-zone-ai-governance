/**
 * Module: org-policy
 * Manages Google Cloud v2 Organization Policies (boolean and list constraints).
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

locals {
  parent = var.organization_id != null ? "organizations/${var.organization_id}" : "folders/${var.folder_id}"
}

# Boolean Organization Policies
resource "google_org_policy_policy" "boolean_policies" {
  for_each = var.boolean_policies

  name   = "${local.parent}/policies/${each.key}"
  parent = local.parent

  spec {
    rules {
      enforce = each.value.enforce ? "TRUE" : "FALSE"
    }
  }
}

# List Organization Policies
resource "google_org_policy_policy" "list_policies" {
  for_each = var.list_policies

  name   = "${local.parent}/policies/${each.key}"
  parent = local.parent

  spec {
    rules {
      dynamic "values" {
        for_each = (each.value.allow_values != null || each.value.deny_values != null) ? [1] : []
        content {
          allowed_values = each.value.allow_values
          denied_values  = each.value.deny_values
        }
      }

      allow_all = each.value.allow_all != null ? (each.value.allow_all ? "TRUE" : "FALSE") : null
      deny_all  = each.value.deny_all != null ? (each.value.deny_all ? "TRUE" : "FALSE") : null
    }
  }
}
