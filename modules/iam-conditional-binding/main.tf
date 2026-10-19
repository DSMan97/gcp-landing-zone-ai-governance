/**
 * Module: iam-conditional-binding
 * Manages IAM bindings at Organization, Folder, or Project levels with CEL condition support.
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

# Project-level IAM bindings
resource "google_project_iam_member" "project_bindings" {
  for_each = {
    for k, v in var.bindings : k => v
    if var.project_id != null
  }

  project = var.project_id
  role    = each.value.role
  member  = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

# Folder-level IAM bindings
resource "google_folder_iam_member" "folder_bindings" {
  for_each = {
    for k, v in var.bindings : k => v
    if var.folder_id != null
  }

  folder = var.folder_id
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}

# Organization-level IAM bindings
resource "google_organization_iam_member" "org_bindings" {
  for_each = {
    for k, v in var.bindings : k => v
    if var.organization_id != null
  }

  org_id = var.organization_id
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = lookup(condition.value, "description", null)
      expression  = condition.value.expression
    }
  }
}
