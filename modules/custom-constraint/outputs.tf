/**
 * Module: custom-constraint - Outputs
 */

output "custom_constraints" {
  description = "List of created custom constraint names."
  value       = keys(google_org_policy_custom_constraint.constraints)
}
