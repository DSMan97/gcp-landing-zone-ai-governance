/**
 * Module: vpc-sc-perimeter
 * Variables definition for VPC Service Controls Service Perimeter.
 */

variable "policy" {
  description = "Access Policy name or numeric ID (e.g., 'accessPolicies/123456789012' or '123456789012')."
  type        = string
}

variable "perimeter_name" {
  description = "Short name of the VPC Service Controls perimeter (e.g., 'sp_regulated_data_shield')."
  type        = string
}

variable "title" {
  description = "Human-readable title for the service perimeter."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the service perimeter purpose and scope."
  type        = string
  default     = "Enterprise VPC Service Controls perimeter for regulated workload data protection."
}

variable "perimeter_type" {
  description = "Perimeter type: PERIMETER_TYPE_REGULAR or PERIMETER_TYPE_BRIDGE."
  type        = string
  default     = "PERIMETER_TYPE_REGULAR"
}

variable "dry_run" {
  description = "Whether the perimeter operates in dry-run mode (logs violations without blocking) or enforced mode."
  type        = bool
  default     = false
}

variable "restricted_services" {
  description = "List of GCP APIs and services restricted by the perimeter."
  type        = list(string)
  default     = []
}

variable "resources" {
  description = "List of GCP projects protected within the perimeter in format 'projects/PROJECT_NUMBER'."
  type        = list(string)
  default     = []
}

variable "access_levels" {
  description = "List of Access Level resource names allowed to bypass the perimeter."
  type        = list(string)
  default     = []
}

variable "vpc_accessible_services" {
  description = "Configuration for VPC accessible services restriction."
  type = object({
    enable_restriction = bool
    allowed_services   = list(string)
  })
  default = null
}

variable "ingress_policies" {
  description = "List of ingress policies to allow external or cross-perimeter ingress access."
  type = list(object({
    from = optional(object({
      identity_type = optional(string)
      identities    = optional(list(string))
      sources = optional(list(object({
        access_level = optional(string)
        resource     = optional(string)
      })))
    }))
    to = optional(object({
      resources = optional(list(string))
      operations = optional(list(object({
        service_name = optional(string)
        method_selectors = optional(list(object({
          method     = optional(string)
          permission = optional(string)
        })))
      })))
    }))
  }))
  default = []
}

variable "egress_policies" {
  description = "List of egress policies to allow outbound data transfer to outside perimeter."
  type = list(object({
    from = optional(object({
      identity_type = optional(string)
      identities    = optional(list(string))
    }))
    to = optional(object({
      resources = optional(list(string))
      operations = optional(list(object({
        service_name = optional(string)
        method_selectors = optional(list(object({
          method     = optional(string)
          permission = optional(string)
        })))
      })))
    }))
  }))
  default = []
}
