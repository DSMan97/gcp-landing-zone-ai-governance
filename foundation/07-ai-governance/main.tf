/**
 * Phase 07: AI Governance - AI Project Template
 * Provisions an enterprise-grade AI template project enclosed within the VPC Service Controls perimeter,
 * equipped with CMEK encryption via Cloud KMS, secure Cloud Storage data lake, and baseline demonstration AI resources.
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

# 1. Standard Data Governance and FinOps Labels
module "ai_labels" {
  source = "../../modules/data-governance-labels"

  environment          = var.environment
  data_classification  = "confidential-pci-hipaa"
  regulated            = true
  cost_center          = var.cost_center
  business_unit        = var.business_unit
  compliance_framework = "nist-ai-rmf-iso-42001-pci-hipaa"
}

# 2. AI Template Project via Project Factory
module "ai_project" {
  source = "../../modules/project-factory"

  name            = var.project_name
  project_id      = var.project_id
  folder_id       = var.folder_id
  billing_account = var.billing_account

  labels = module.ai_labels.labels

  services = [
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
}

# 3. Cryptographic Governance: Cloud KMS CMEK for AI Workloads
resource "google_kms_key_ring" "ai_keyring" {
  name     = "kr-ai-governance-${var.primary_region}"
  project  = module.ai_project.project_id
  location = var.primary_region
}

resource "google_kms_crypto_key" "ai_cmek_key" {
  name            = "key-ai-governance-cmek"
  key_ring        = google_kms_key_ring.ai_keyring.id
  rotation_period = "7776000s" # 90 days automatic key rotation
  purpose         = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = true
  }
}

# 4. Service Agents & IAM Grants for CMEK Decryption/Encryption
resource "google_project_service_identity" "storage_sa" {
  provider = google-beta
  project  = module.ai_project.project_id
  service  = "storage.googleapis.com"
}

resource "google_project_service_identity" "aiplatform_sa" {
  provider = google-beta
  project  = module.ai_project.project_id
  service  = "aiplatform.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "storage_cmek_binding" {
  crypto_key_id = google_kms_crypto_key.ai_cmek_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.storage_sa.email}"
}

resource "google_kms_crypto_key_iam_member" "aiplatform_cmek_binding" {
  crypto_key_id = google_kms_crypto_key.ai_cmek_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.aiplatform_sa.email}"
}

# 5. Secure AI Data Lake Bucket
resource "google_storage_bucket" "ai_data_bucket" {
  name                        = "bkt-ai-governance-data-${module.ai_project.project_id}"
  project                     = module.ai_project.project_id
  location                    = var.primary_region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.ai_cmek_key.id
  }

  labels = module.ai_labels.labels

  depends_on = [
    google_kms_crypto_key_iam_member.storage_cmek_binding
  ]
}

# Baseline Storage Structure for AI Lifecycle
resource "google_storage_bucket_object" "training_dir" {
  name         = "training-data/"
  content      = " "
  bucket       = google_storage_bucket.ai_data_bucket.name
  kms_key_name = google_kms_crypto_key.ai_cmek_key.id

  depends_on = [
    google_kms_crypto_key_iam_member.storage_cmek_binding
  ]
}

resource "google_storage_bucket_object" "models_dir" {
  name         = "models/"
  content      = " "
  bucket       = google_storage_bucket.ai_data_bucket.name
  kms_key_name = google_kms_crypto_key.ai_cmek_key.id

  depends_on = [
    google_kms_crypto_key_iam_member.storage_cmek_binding
  ]
}

resource "google_storage_bucket_object" "demo_dataset_file" {
  name         = "training-data/clinical_sample_dataset.csv"
  content      = "patient_id,feature_1,feature_2,label\nP001,0.85,1.23,0\nP002,0.42,0.91,1\n"
  bucket       = google_storage_bucket.ai_data_bucket.name
  content_type = "text/csv"
  kms_key_name = google_kms_crypto_key.ai_cmek_key.id

  depends_on = [
    google_kms_crypto_key_iam_member.storage_cmek_binding
  ]
}

# 6. Baseline Demonstration AI Resources
# Artifact Registry for AI container images (Training / Serving)
resource "google_artifact_registry_repository" "ai_models_repo" {
  repository_id = "ar-ai-models-${var.primary_region}"
  project       = module.ai_project.project_id
  location      = var.primary_region
  format        = "DOCKER"
  description   = "Docker container repository for custom AI Agent models and inference pipelines"
  kms_key_name  = google_kms_crypto_key.ai_cmek_key.id

  labels = module.ai_labels.labels

  depends_on = [
    google_kms_crypto_key_iam_member.aiplatform_cmek_binding
  ]
}

# Vertex AI Tensorboard for Experiment Tracking
resource "google_vertex_ai_tensorboard" "demo_tensorboard" {
  display_name = "tb-ai-experiments-demo"
  description  = "Vertex AI Tensorboard instance for ML experiment tracking and auditability"
  region       = var.primary_region
  project      = module.ai_project.project_id

  encryption_spec {
    kms_key_name = google_kms_crypto_key.ai_cmek_key.id
  }

  labels = module.ai_labels.labels

  depends_on = [
    google_kms_crypto_key_iam_member.aiplatform_cmek_binding
  ]
}

# Vertex AI Model Prediction Endpoint (Demo)
resource "google_vertex_ai_endpoint" "demo_endpoint" {
  name         = "ep-ai-agent-governance-demo"
  display_name = "ep-ai-agent-governance-demo"
  description  = "Governed Vertex AI inference endpoint secured with CMEK and VPC-SC isolation"
  location     = var.primary_region
  project      = module.ai_project.project_id

  encryption_spec {
    kms_key_name = google_kms_crypto_key.ai_cmek_key.id
  }

  labels = module.ai_labels.labels

  depends_on = [
    google_kms_crypto_key_iam_member.aiplatform_cmek_binding
  ]
}

# 7. VPC Service Controls: Integration into Security Perimeter
resource "google_access_context_manager_service_perimeter_resource" "ai_project_perimeter_membership" {
  count          = var.service_perimeter_name != "" ? 1 : 0
  perimeter_name = var.service_perimeter_name
  resource       = "projects/${module.ai_project.project_number}"
}
