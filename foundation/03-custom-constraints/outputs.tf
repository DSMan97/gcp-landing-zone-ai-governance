/**
 * Phase 03: Custom Constraints - Outputs
 */

output "created_custom_constraints" {
  description = "List of created custom constraint names."
  value       = module.custom_constraints.custom_constraints
}
