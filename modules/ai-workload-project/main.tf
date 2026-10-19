/**
 * Module: ai-workload-project
 * Standardized, enterprise-grade AI Workload Project Factory.
 * Deploys an AI/ML project with required Vertex AI APIs, governance labels, CMEK encryption,
 * secure data lake buckets, Artifact Registry, and baseline experiment/inference resources.
 */

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0.0"
    }
  }
}

# 1. Standard Data Governance and FinOps Labels
module "labels" {
  source = "../data-governance-labels"

  environment          = var.environment
  data_classification  = var.data_classification
  regulated            = var.regulated
  cost_center          = var.cost_center
  business_unit        = var.business_unit
  compliance_framework = var.compliance_framework
  additional_labels    = var.additional_labels
}

# 2. Hardened GCP Project via Project Factory
locals {
  default_ai_services = [
    "aiplatform.googleapis.com",
    "notebooks.googleapis.com",
    "storage.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "servicenetworking.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "datacatalog.googleapis.com"
  ]

  all_services = distinct(concat(local.default_ai_services, var.additional_services))
}

module "project" {
  source = "../project-factory"

  name            = var.project_name
  project_id      = var.project_id
  folder_id       = var.folder_id
  billing_account = var.billing_account

  labels   = module.labels.labels
  services = local.all_services
}

# 3. Cryptographic Governance: Cloud KMS CMEK Module
module "cmek" {
  count  = var.create_cmek ? 1 : 0
  source = "../cmek-kms"

  project_id      = module.project.project_id
  location        = var.primary_region
  keyring_name    = var.cmek_keyring_name != "" ? var.cmek_keyring_name : "kr-${var.project_id}-${var.primary_region}"
  key_name        = var.cmek_key_name != "" ? var.cmek_key_name : "key-${var.project_id}-cmek"
  rotation_period = var.cmek_rotation_period
  labels          = module.labels.labels

  service_identities = distinct(concat([
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com"
  ], var.additional_service_identities))

  encrypter_decrypter_members = var.custom_kms_encrypter_decrypters
}

locals {
  cmek_key_id = var.create_cmek ? module.cmek[0].crypto_key_id : var.existing_cmek_crypto_key_id
}

# 4. Secure AI Data Lake Bucket
resource "google_storage_bucket" "ai_data_bucket" {
  count = var.create_storage_bucket ? 1 : 0

  name                        = var.storage_bucket_name != "" ? var.storage_bucket_name : "bkt-ai-data-${module.project.project_id}"
  project                     = module.project.project_id
  location                    = var.primary_region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  dynamic "encryption" {
    for_each = local.cmek_key_id != "" ? [1] : []
    content {
      default_kms_key_name = local.cmek_key_id
    }
  }

  labels = module.labels.labels

  depends_on = [
    module.cmek
  ]
}

# Baseline Storage Structure for AI Lifecycle
resource "google_storage_bucket_object" "training_dir" {
  count = var.create_storage_bucket && var.create_default_storage_folders ? 1 : 0

  name         = "training-data/"
  content      = " "
  bucket       = google_storage_bucket.ai_data_bucket[0].name
  kms_key_name = local.cmek_key_id != "" ? local.cmek_key_id : null

  depends_on = [
    module.cmek
  ]
}

resource "google_storage_bucket_object" "models_dir" {
  count = var.create_storage_bucket && var.create_default_storage_folders ? 1 : 0

  name         = "models/"
  content      = " "
  bucket       = google_storage_bucket.ai_data_bucket[0].name
  kms_key_name = local.cmek_key_id != "" ? local.cmek_key_id : null

  depends_on = [
    module.cmek
  ]
}

resource "google_storage_bucket_object" "demo_dataset_file" {
  count = var.create_storage_bucket && var.create_demo_dataset ? 1 : 0

  name         = "training-data/clinical_sample_dataset.csv"
  content      = "patient_id,feature_1,feature_2,label\nP001,0.85,1.23,0\nP002,0.42,0.91,1\n"
  bucket       = google_storage_bucket.ai_data_bucket[0].name
  content_type = "text/csv"
  kms_key_name = local.cmek_key_id != "" ? local.cmek_key_id : null

  depends_on = [
    module.cmek
  ]
}

# 5. Artifact Registry for AI container images
resource "google_artifact_registry_repository" "ai_models_repo" {
  count = var.create_artifact_registry ? 1 : 0

  repository_id = var.artifact_registry_name != "" ? var.artifact_registry_name : "ar-ai-models-${var.primary_region}"
  project       = module.project.project_id
  location      = var.primary_region
  format        = "DOCKER"
  description   = "Docker container repository for custom AI Agent models and inference pipelines"
  kms_key_name  = local.cmek_key_id != "" ? local.cmek_key_id : null

  labels = module.labels.labels

  depends_on = [
    module.cmek
  ]
}

# 6. Optional Baseline Demonstration / Experimentation Resources
resource "google_vertex_ai_tensorboard" "tensorboard" {
  count = var.create_tensorboard ? 1 : 0

  display_name = var.tensorboard_display_name != "" ? var.tensorboard_display_name : "tb-ai-experiments-${var.environment}"
  description  = "Vertex AI Tensorboard instance for ML experiment tracking and auditability"
  region       = var.primary_region
  project      = module.project.project_id

  dynamic "encryption_spec" {
    for_each = local.cmek_key_id != "" ? [1] : []
    content {
      kms_key_name = local.cmek_key_id
    }
  }

  labels = module.labels.labels

  depends_on = [
    module.cmek
  ]
}

resource "google_vertex_ai_endpoint" "endpoint" {
  count = var.create_endpoint ? 1 : 0

  name         = var.endpoint_name != "" ? var.endpoint_name : "ep-ai-agent-${var.environment}-demo"
  display_name = var.endpoint_name != "" ? var.endpoint_name : "ep-ai-agent-${var.environment}-demo"
  description  = "Governed Vertex AI inference endpoint secured with CMEK and VPC-SC isolation"
  location     = var.primary_region
  project      = module.project.project_id

  dynamic "encryption_spec" {
    for_each = local.cmek_key_id != "" ? [1] : []
    content {
      kms_key_name = local.cmek_key_id
    }
  }

  labels = module.labels.labels

  depends_on = [
    module.cmek
  ]
}

# 7. VPC Service Controls - Perimeter Resource Enrollment (Optional)
resource "google_access_context_manager_service_perimeter_resource" "perimeter_membership" {
  count = var.service_perimeter_name != "" ? 1 : 0

  perimeter_name = var.service_perimeter_name
  resource       = "projects/${module.project.project_number}"
}
