/**
 * Module: org-policy - Outputs
 */

output "enforced_boolean_policies" {
  description = "List of enforced boolean organization policies."
  value       = keys(google_org_policy_policy.boolean_policies)
}

output "enforced_list_policies" {
  description = "List of enforced list organization policies."
  value       = keys(google_org_policy_policy.list_policies)
}
