/**
 * Module: cmek-kms
 * Reusable Customer-Managed Encryption Key (CMEK) module for Cloud KMS.
 * Manages KeyRings, CryptoKeys with automated rotation and IAM bindings for GCP Service Agents and identities.
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

# 1. KMS KeyRing
resource "google_kms_key_ring" "keyring" {
  name     = var.keyring_name
  project  = var.project_id
  location = var.location
}

# 2. CMEK CryptoKey with Automated Rotation
resource "google_kms_crypto_key" "crypto_key" {
  name            = var.key_name
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = var.rotation_period
  purpose         = var.purpose
  labels          = var.labels

  destroy_scheduled_duration = var.destroy_scheduled_duration
}

# 3. Google Service Identities (Service Agents)
resource "google_project_service_identity" "service_agents" {
  provider = google-beta
  for_each = toset(var.service_identities)

  project = var.project_id
  service = each.value
}

# 4. IAM Bindings for Service Agents (Encrypter/Decrypter)
resource "google_kms_crypto_key_iam_member" "service_agent_cmek_bindings" {
  for_each = google_project_service_identity.service_agents

  crypto_key_id = google_kms_crypto_key.crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${each.value.email}"
}

# 5. IAM Bindings for Additional Custom Members / Service Accounts
resource "google_kms_crypto_key_iam_member" "custom_cmek_bindings" {
  for_each = toset(var.encrypter_decrypter_members)

  crypto_key_id = google_kms_crypto_key.crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value
}
