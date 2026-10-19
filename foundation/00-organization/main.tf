/**
 * Phase 00: Organization - Base Settings, Essential Contacts, SCC & Access Transparency
 * Configures core organization metadata, security notification channels,
 * Security Command Center organization-level streaming findings, and Access Approval/Transparency.
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

# 1. Essential Contacts for Security, Compliance, and Billing notifications
resource "google_essential_contacts_contact" "security_contact" {
  parent                              = "organizations/${var.organization_id}"
  email                               = var.security_team_email
  language_tag                        = "es"
  notification_category_subscriptions = ["SECURITY", "SUSPENSION", "TECHNICAL"]
}

resource "google_essential_contacts_contact" "legal_contact" {
  parent                              = "organizations/${var.organization_id}"
  email                               = var.legal_team_email
  language_tag                        = "es"
  notification_category_subscriptions = ["LEGAL", "COMPLIANCE"]
}

resource "google_essential_contacts_contact" "billing_contact" {
  parent                              = "organizations/${var.organization_id}"
  email                               = var.billing_team_email
  language_tag                        = "es"
  notification_category_subscriptions = ["BILLING", "TECHNICAL"]
}

# 2. Security Command Center (SCC) at Organization Level
# Streaming notification config for real-time alerting on HIGH and CRITICAL findings
resource "google_scc_notification_config" "scc_org_notification" {
  count        = var.enable_scc_notifications ? 1 : 0
  config_id    = "scc-org-high-critical-alerts"
  organization = var.organization_id
  description  = "Security Command Center organization-level streaming notification for active HIGH and CRITICAL findings"
  pubsub_topic = var.scc_notification_pubsub_topic

  streaming_config {
    filter = "state=\"ACTIVE\" AND (severity=\"HIGH\" OR severity=\"CRITICAL\")"
  }
}

# SCC Mute Config for Development noise suppression at organization level
resource "google_scc_mute_config" "scc_dev_mute_rule" {
  count          = var.enable_scc_notifications ? 1 : 0
  mute_config_id = "mute-low-priority-dev-scans"
  parent         = "organizations/${var.organization_id}"
  filter         = "category=\"RESOURCE_NOT_DEFENDED\" AND resource.project_display_name:\"dev\""
  description    = "Mutes non-critical development environment scanner alerts for operational hygiene"
}

# 3. Access Transparency & Access Approval at Organization Level
# Enforces manual approval and audit trail for Google Cloud administrative access
resource "google_organization_access_approval_settings" "org_access_approval" {
  count               = var.enable_access_approval ? 1 : 0
  organization_id     = var.organization_id
  notification_emails = [var.security_team_email, var.legal_team_email]

  enrolled_services {
    cloud_product = "all"
  }
}
