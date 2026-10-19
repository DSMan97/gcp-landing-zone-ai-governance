/**
 * Module: cmek-kms - Variables
 */

variable "project_id" {
  description = "The GCP project ID where the KMS KeyRing and CryptoKey will be created."
  type        = string
}

variable "location" {
  description = "The GCP location/region for the KMS KeyRing (e.g. europe-west1, europe-west3)."
  type        = string
}

variable "keyring_name" {
  description = "Name of the KMS KeyRing."
  type        = string
}

variable "key_name" {
  description = "Name of the KMS CryptoKey."
  type        = string
}

variable "rotation_period" {
  description = "Automatic rotation period for the CryptoKey (default: 90 days = 7776000s)."
  type        = string
  default     = "7776000s"
}

variable "purpose" {
  description = "The immutable purpose of the CryptoKey."
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "destroy_scheduled_duration" {
  description = "The period of time that versions of this key spend in the DESTROY_SCHEDULED state before being permanently deleted."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to attach to the CryptoKey."
  type        = map(string)
  default     = {}
}

variable "service_identities" {
  description = "List of GCP service agent identifiers to create and grant roles/cloudkms.cryptoKeyEncrypterDecrypter (e.g. storage.googleapis.com, aiplatform.googleapis.com, bigquery.googleapis.com, artifactregistry.googleapis.com)."
  type        = list(string)
  default     = []
}

variable "encrypter_decrypter_members" {
  description = "List of additional IAM members to grant roles/cloudkms.cryptoKeyEncrypterDecrypter (e.g. serviceAccount:my-sa@...). "
  type        = list(string)
  default     = []
}
