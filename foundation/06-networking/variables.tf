/**
 * Phase 06: Networking & VPC Service Controls - Variables
 */

variable "organization_id" {
  description = "The GCP Organization ID for Access Context Manager policy."
  type        = string
}

variable "network_host_project_id" {
  description = "The GCP Project ID hosting the Shared VPC."
  type        = string
  default     = "prj-net-shared-hub"
}

variable "primary_region" {
  description = "Primary region for network deployment."
  type        = string
  default     = "europe-west1"
}

variable "psc_endpoint_ip" {
  description = "The internal IP address reserved for Private Service Connect (PSC) endpoint for Google APIs."
  type        = string
  default     = "10.100.100.100"
}

variable "access_policy_title" {
  description = "Title for the Access Context Manager policy."
  type        = string
  default     = "Enterprise Security & Data Protection Policy"
}

variable "service_perimeter_name" {
  description = "Name identifier for the VPC Service Controls perimeter."
  type        = string
  default     = "sp_regulated_data_shield"
}

variable "trusted_ingress_ip_ranges" {
  description = "List of corporate / trusted CIDRs permitted in Access Context Manager Access Level."
  type        = list(string)
  default = [
    "198.51.100.0/24",
    "203.0.113.0/24"
  ]
}

variable "protected_projects" {
  description = "List of project numbers or resource URIs enclosed by the VPC-SC perimeter."
  type        = list(string)
  default     = []
}

variable "restricted_services" {
  description = "List of Google Cloud and AI services restricted within the VPC-SC perimeter (Google recommends restricting all supported APIs)."
  type        = list(string)
  default = [
    "aiplatform.googleapis.com",
    "notebooks.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "datacatalog.googleapis.com",
    "dataproc.googleapis.com",
    "dialogflow.googleapis.com",
    "discoveryengine.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com"
  ]
}

variable "authorized_ingress_identities" {
  description = "List of specific identities permitted by ingress policies (e.g., service accounts, user groups)."
  type        = list(string)
  default     = []
}
