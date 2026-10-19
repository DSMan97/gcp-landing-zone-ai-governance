/**
 * Module: vpc-sc-perimeter
 * Provisions and manages a VPC Service Controls perimeter (regular or bridge) in enforced or dry-run mode.
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

locals {
  policy_id = startswith(var.policy, "accessPolicies/") ? var.policy : "accessPolicies/${var.policy}"
}

resource "google_access_context_manager_service_perimeter" "perimeter" {
  parent         = local.policy_id
  name           = "${local.policy_id}/servicePerimeters/${var.perimeter_name}"
  title          = var.title != null && var.title != "" ? var.title : var.perimeter_name
  description    = var.description
  perimeter_type = var.perimeter_type

  use_explicit_dry_run_spec = var.dry_run

  dynamic "status" {
    for_each = var.dry_run ? [] : [1]
    content {
      restricted_services = var.restricted_services
      resources           = var.resources
      access_levels       = var.access_levels

      dynamic "vpc_accessible_services" {
        for_each = var.vpc_accessible_services != null ? [var.vpc_accessible_services] : []
        content {
          enable_restriction = vpc_accessible_services.value.enable_restriction
          allowed_services   = vpc_accessible_services.value.allowed_services
        }
      }

      dynamic "ingress_policies" {
        for_each = var.ingress_policies
        content {
          dynamic "ingress_from" {
            for_each = ingress_policies.value.from != null ? [ingress_policies.value.from] : []
            content {
              identity_type = ingress_from.value.identity_type
              identities    = ingress_from.value.identities

              dynamic "sources" {
                for_each = ingress_from.value.sources != null ? ingress_from.value.sources : []
                content {
                  access_level = sources.value.access_level
                  resource     = sources.value.resource
                }
              }
            }
          }

          dynamic "ingress_to" {
            for_each = ingress_policies.value.to != null ? [ingress_policies.value.to] : []
            content {
              resources = ingress_to.value.resources != null ? ingress_to.value.resources : ["*"]

              dynamic "operations" {
                for_each = ingress_to.value.operations != null ? ingress_to.value.operations : [{ service_name = "*" }]
                content {
                  service_name = operations.value.service_name

                  dynamic "method_selectors" {
                    for_each = operations.value.method_selectors != null ? operations.value.method_selectors : []
                    content {
                      method     = method_selectors.value.method
                      permission = method_selectors.value.permission
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "egress_policies" {
        for_each = var.egress_policies
        content {
          dynamic "egress_from" {
            for_each = egress_policies.value.from != null ? [egress_policies.value.from] : []
            content {
              identity_type = egress_from.value.identity_type
              identities    = egress_from.value.identities
            }
          }

          dynamic "egress_to" {
            for_each = egress_policies.value.to != null ? [egress_policies.value.to] : []
            content {
              resources = egress_to.value.resources != null ? egress_to.value.resources : ["*"]

              dynamic "operations" {
                for_each = egress_to.value.operations != null ? egress_to.value.operations : [{ service_name = "*" }]
                content {
                  service_name = operations.value.service_name

                  dynamic "method_selectors" {
                    for_each = operations.value.method_selectors != null ? operations.value.method_selectors : []
                    content {
                      method     = method_selectors.value.method
                      permission = method_selectors.value.permission
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "spec" {
    for_each = var.dry_run ? [1] : []
    content {
      restricted_services = var.restricted_services
      resources           = var.resources
      access_levels       = var.access_levels

      dynamic "vpc_accessible_services" {
        for_each = var.vpc_accessible_services != null ? [var.vpc_accessible_services] : []
        content {
          enable_restriction = vpc_accessible_services.value.enable_restriction
          allowed_services   = vpc_accessible_services.value.allowed_services
        }
      }

      dynamic "ingress_policies" {
        for_each = var.ingress_policies
        content {
          dynamic "ingress_from" {
            for_each = ingress_policies.value.from != null ? [ingress_policies.value.from] : []
            content {
              identity_type = ingress_from.value.identity_type
              identities    = ingress_from.value.identities

              dynamic "sources" {
                for_each = ingress_from.value.sources != null ? ingress_from.value.sources : []
                content {
                  access_level = sources.value.access_level
                  resource     = sources.value.resource
                }
              }
            }
          }

          dynamic "ingress_to" {
            for_each = ingress_policies.value.to != null ? [ingress_policies.value.to] : []
            content {
              resources = ingress_to.value.resources != null ? ingress_to.value.resources : ["*"]

              dynamic "operations" {
                for_each = ingress_to.value.operations != null ? ingress_to.value.operations : [{ service_name = "*" }]
                content {
                  service_name = operations.value.service_name

                  dynamic "method_selectors" {
                    for_each = operations.value.method_selectors != null ? operations.value.method_selectors : []
                    content {
                      method     = method_selectors.value.method
                      permission = method_selectors.value.permission
                    }
                  }
                }
              }
            }
          }
        }
      }

      dynamic "egress_policies" {
        for_each = var.egress_policies
        content {
          dynamic "egress_from" {
            for_each = egress_policies.value.from != null ? [egress_policies.value.from] : []
            content {
              identity_type = egress_from.value.identity_type
              identities    = egress_from.value.identities
            }
          }

          dynamic "egress_to" {
            for_each = egress_policies.value.to != null ? [egress_policies.value.to] : []
            content {
              resources = egress_to.value.resources != null ? egress_to.value.resources : ["*"]

              dynamic "operations" {
                for_each = egress_to.value.operations != null ? egress_to.value.operations : [{ service_name = "*" }]
                content {
                  service_name = operations.value.service_name

                  dynamic "method_selectors" {
                    for_each = operations.value.method_selectors != null ? operations.value.method_selectors : []
                    content {
                      method     = method_selectors.value.method
                      permission = method_selectors.value.permission
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
