/**
 * Module: project-factory - Variables
 */

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "name" {
  description = "The display name of the GCP project."
  type        = string
}

variable "folder_id" {
  description = "The parent folder ID for the project."
  type        = string
}

variable "billing_account" {
  description = "The billing account ID to associate with this project."
  type        = string
}

variable "services" {
  description = "List of GCP API services to enable."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudkms.googleapis.com",
    "bigquery.googleapis.com",
    "sqladmin.googleapis.com",
    "accesscontextmanager.googleapis.com"
  ]
}

variable "labels" {
  description = "Mandatory labels for data governance and FinOps."
  type        = map(string)
  default = {
    environment         = "production"
    data_classification = "confidential-pci-hipaa"
    regulated           = "true"
  }
}

variable "auto_create_network" {
  description = "Whether to create default network (MUST BE FALSE for enterprise security)."
  type        = bool
  default     = false
}
