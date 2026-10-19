/**
 * Module: org-policy - Variables
 */

variable "organization_id" {
  description = "The GCP Organization ID to apply policies to."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "The GCP Folder ID to apply policies to (if targeting a folder)."
  type        = string
  default     = null
}

variable "boolean_policies" {
  description = "Map of boolean organization policy constraints to enforce."
  type = map(object({
    enforce = bool
  }))
  default = {}
}

variable "list_policies" {
  description = "Map of list organization policy constraints with allow/deny values."
  type = map(object({
    allow_values = optional(list(string))
    deny_values  = optional(list(string))
    allow_all    = optional(bool)
    deny_all     = optional(bool)
  }))
  default = {}
}
