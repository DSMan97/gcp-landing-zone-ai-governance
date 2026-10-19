/**
 * Phase 04: IAM - Outputs
 */

output "assigned_folder_bindings" {
  description = "List of assigned folder IAM member bindings."
  value       = module.production_iam.folder_bindings
}

output "managed_workspace_groups" {
  description = "List and details of managed Google Workspace security groups."
  value = var.manage_workspace_groups ? {
    legal_team      = try(googleworkspace_group.legal_compliance_group[0].email, var.legal_team_group)
    soc_team        = try(googleworkspace_group.soc_team_group[0].email, var.soc_team_group)
    break_glass     = try(googleworkspace_group.break_glass_group[0].email, var.break_glass_group)
    data_scientists = try(googleworkspace_group.data_scientists_group[0].email, var.data_scientists_group)
    agent_deployers = try(googleworkspace_group.agent_deployers_group[0].email, var.agent_deployers_group)
    ai_auditors     = try(googleworkspace_group.ai_auditors_group[0].email, var.ai_auditors_group)
  } : null
}

output "workload_service_accounts" {
  description = "Map of dedicated workload service accounts."
  value = {
    training      = local.sa_training_email
    serving       = local.sa_serving_email
    vector_search = local.sa_vector_search_email
  }
}
