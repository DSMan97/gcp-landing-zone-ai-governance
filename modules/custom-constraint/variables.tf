/**
 * Module: custom-constraint - Variables
 */

variable "organization_id" {
  description = "The GCP Organization ID where custom constraints are registered."
  type        = string
}

variable "custom_constraints" {
  description = "List of custom constraints defined using CEL expressions."
  type = list(object({
    name           = string
    resource_types = list(string)
    method_types   = list(string)
    condition      = string
    action_type    = string
    display_name   = string
    description    = string
  }))
  default = []
}
