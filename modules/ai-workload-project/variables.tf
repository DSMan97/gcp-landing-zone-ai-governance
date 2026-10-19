/**
 * Module: ai-workload-project - Variables
 */

variable "project_id" {
  description = "The GCP Project ID for the AI workload project."
  type        = string
}

variable "project_name" {
  description = "Display name of the AI workload project."
  type        = string
}

variable "folder_id" {
  description = "Parent Folder ID where the AI project will be created."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID to associate with the AI project."
  type        = string
}

variable "primary_region" {
  description = "Primary GCP region for Vertex AI, Cloud KMS, and Cloud Storage resources (e.g. europe-west1)."
  type        = string
  default     = "europe-west1"
}

variable "environment" {
  description = "Target environment tier (e.g., prod, stg, dev)."
  type        = string
  default     = "prod"
}

variable "data_classification" {
  description = "Data classification level (e.g. confidential-pci-hipaa, internal, restricted)."
  type        = string
  default     = "confidential-pci-hipaa"
}

variable "regulated" {
  description = "Whether the AI workload processes regulated data (PCI, HIPAA, GDPR)."
  type        = bool
  default     = true
}

variable "cost_center" {
  description = "Cost Center code for FinOps allocation."
  type        = string
  default     = "cc-ai-agent-governance"
}

variable "business_unit" {
  description = "Business Unit responsible for the AI workload."
  type        = string
  default     = "ai-clinical-fintech"
}

variable "compliance_framework" {
  description = "Primary compliance framework (e.g. nist-ai-rmf-iso-42001-pci-hipaa)."
  type        = string
  default     = "nist-ai-rmf-iso-42001-pci-hipaa"
}

variable "additional_labels" {
  description = "Additional custom labels to merge."
  type        = map(string)
  default     = {}
}

variable "additional_services" {
  description = "Additional APIs to enable on top of baseline AI services."
  type        = list(string)
  default     = []
}

# Cryptographic Governance (CMEK)
variable "create_cmek" {
  description = "Whether to create a dedicated Cloud KMS CMEK KeyRing and CryptoKey."
  type        = bool
  default     = true
}

variable "cmek_keyring_name" {
  description = "Custom name for the KMS KeyRing. If empty, a standard name is generated."
  type        = string
  default     = ""
}

variable "cmek_key_name" {
  description = "Custom name for the KMS CryptoKey. If empty, a standard name is generated."
  type        = string
  default     = ""
}

variable "cmek_rotation_period" {
  description = "Automatic rotation period for the CMEK key (default: 90 days = 7776000s)."
  type        = string
  default     = "7776000s"
}

variable "additional_service_identities" {
  description = "Additional service agents to grant CMEK EncrypterDecrypter permissions."
  type        = list(string)
  default     = []
}

variable "custom_kms_encrypter_decrypters" {
  description = "Additional IAM members to grant CMEK EncrypterDecrypter permissions."
  type        = list(string)
  default     = []
}

variable "existing_cmek_crypto_key_id" {
  description = "Existing Cloud KMS CryptoKey ID if create_cmek is set to false."
  type        = string
  default     = ""
}

# Cloud Storage
variable "create_storage_bucket" {
  description = "Whether to create a secure AI Data Lake Cloud Storage bucket."
  type        = bool
  default     = true
}

variable "storage_bucket_name" {
  description = "Custom name for the AI Data Lake bucket. If empty, standard naming is used."
  type        = string
  default     = ""
}

variable "create_default_storage_folders" {
  description = "Whether to create training-data/ and models/ initial directory structures in GCS."
  type        = bool
  default     = true
}

variable "create_demo_dataset" {
  description = "Whether to upload a baseline demonstration sample dataset into Cloud Storage."
  type        = bool
  default     = true
}

# Artifact Registry
variable "create_artifact_registry" {
  description = "Whether to create a CMEK-encrypted Artifact Registry Docker repository for AI containers."
  type        = bool
  default     = true
}

variable "artifact_registry_name" {
  description = "Custom name for the Artifact Registry repository."
  type        = string
  default     = ""
}

# Vertex AI Baseline / Demo Resources
variable "create_tensorboard" {
  description = "Whether to create a baseline Vertex AI Tensorboard instance."
  type        = bool
  default     = true
}

variable "tensorboard_display_name" {
  description = "Display name for Vertex AI Tensorboard."
  type        = string
  default     = ""
}

variable "create_endpoint" {
  description = "Whether to create a baseline Vertex AI Prediction Endpoint."
  type        = bool
  default     = true
}

variable "endpoint_name" {
  description = "Name for the Vertex AI Prediction Endpoint."
  type        = string
  default     = ""
}

# VPC Service Controls
variable "service_perimeter_name" {
  description = "The full resource name of the VPC Service Controls perimeter to enroll this project in. If empty, perimeter enrollment is skipped."
  type        = string
  default     = ""
}
