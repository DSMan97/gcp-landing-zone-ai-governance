/**
 * Fase 02: Organization Policies
 * Enforces mandatory baseline guardrails across the GCP Organization.
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

module "org_guardrails" {
  source = "../../modules/org-policy"

  organization_id = var.organization_id

  boolean_policies = {
    "compute.skipDefaultNetworkCreation"              = { enforce = true }
    "compute.requireOsLogin"                          = { enforce = true }
    "compute.disableSerialPortAccess"                 = { enforce = true }
    "iam.disableServiceAccountKeyCreation"            = { enforce = true }
    "iam.disableServiceAccountKeyUpload"              = { enforce = true }
    "iam.automaticIamGrantsForDefaultServiceAccounts" = { enforce = true }
    "sql.restrictPublicIp"                            = { enforce = true }
    "storage.uniformBucketLevelAccess"                = { enforce = true }
    "essentialcontacts.disableNotificationCategories" = { enforce = false }

    # Vertex AI Workbench & AI Notebooks Restrictions
    "ainotebooks.restrictPublicIp"     = { enforce = true }
    "ainotebooks.restrictRootAccess"   = { enforce = true }
    "ainotebooks.disableFileDownloads" = { enforce = true }
    "ainotebooks.requireAutoUpgrade"   = { enforce = true }
  }

  list_policies = {
    "compute.vmExternalIpAccess" = {
      deny_all = true
    }

    "gcp.resourceLocations" = {
      allow_values = [
        "in:eu-locations", # Permite desplegar en todas las regiones de Europa para cumplir la GDPR
      ]
    }

    "iam.allowedPolicyMemberDomains" = {
      allow_values = [
        "C01234567" # Customer Directory ID for enterprise domain
      ]
    }

    # Restricción gestionada de modo de acceso de Workbench / Notebooks (VertexAI/AgentPlatform)
    "ainotebooks.accessMode" = {
      allow_values = [
        "SERVICE_ACCOUNT",
        "single-user"
      ]
    }
  }
}
