/**
 * Phase 02: Organization Policies - Outputs
 */

output "enforced_boolean_policies" {
  description = "List of enforced boolean organization policies."
  value       = module.org_guardrails.enforced_boolean_policies
}

output "enforced_list_policies" {
  description = "List of enforced list organization policies."
  value       = module.org_guardrails.enforced_list_policies
}
