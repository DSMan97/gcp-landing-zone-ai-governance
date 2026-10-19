/**
 * Module: iam-conditional-binding - Variables
 */

variable "project_id" {
  description = "The target GCP Project ID."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "The target GCP Folder ID."
  type        = string
  default     = null
}

variable "organization_id" {
  description = "The target GCP Organization ID."
  type        = string
  default     = null
}

variable "bindings" {
  description = "Map of individual IAM member bindings with roles and optional CEL conditions."
  type = map(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = optional(string)
      expression  = string
    }))
  }))
  default = {}
}
