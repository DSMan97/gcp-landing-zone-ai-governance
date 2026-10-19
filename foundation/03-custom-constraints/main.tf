/**
 * Phase 03: Custom Constraints - Advanced CEL Guardrails
 * Provisions custom constraints enforcing BigQuery CMEK, Storage Uniform Access,
 * and Agent Platform guardrails (Training, Predictions, and Vector Search) via YAML CEL definitions.
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
  yaml_files = fileset("${path.module}/constraints", "*.yaml")

  yaml_constraints_raw = flatten([
    for file in local.yaml_files : yamldecode(file("${path.module}/constraints/${file}"))
  ])

  parsed_yaml_constraints = [
    for c in local.yaml_constraints_raw : {
      name           = c.name
      display_name   = try(c.display_name, c.displayName)
      description    = try(c.description, "")
      action_type    = try(c.action_type, c.actionType)
      condition      = c.condition
      method_types   = try(c.method_types, c.methodTypes)
      resource_types = try(c.resource_types, c.resourceTypes)
    }
  ]

  base_constraints = [
    {
      name         = "custom.requireBigQueryCmek"
      display_name = "Enforce CMEK on BigQuery Datasets"
      description  = "Requires default KMS key encryption configuration for all BigQuery datasets in production/clinical platforms."
      action_type  = "DENY"
      condition    = "!has(resource.defaultEncryptionConfiguration.kmsKeyName) || resource.defaultEncryptionConfiguration.kmsKeyName == ''"
      method_types = ["CREATE", "UPDATE"]
      resource_types = [
        "bigquery.googleapis.com/Dataset"
      ]
    },
    {
      name         = "custom.storagePreventPublicAccess"
      display_name = "Prevent Public Cloud Storage Buckets"
      description  = "Denies creation of buckets without uniform bucket level access enabled."
      action_type  = "DENY"
      condition    = "!resource.uniformBucketLevelAccess.enabled"
      method_types = ["CREATE", "UPDATE"]
      resource_types = [
        "storage.googleapis.com/Bucket"
      ]
    }
  ]
}

module "custom_constraints" {
  source = "../../modules/custom-constraint"

  organization_id = var.organization_id

  custom_constraints = concat(local.base_constraints, local.parsed_yaml_constraints)
}
