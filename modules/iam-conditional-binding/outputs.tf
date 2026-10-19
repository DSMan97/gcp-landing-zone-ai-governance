/**
 * Module: iam-conditional-binding - Outputs
 */

output "project_bindings" {
  description = "Assigned project IAM members."
  value       = keys(google_project_iam_member.project_bindings)
}

output "folder_bindings" {
  description = "Assigned folder IAM members."
  value       = keys(google_folder_iam_member.folder_bindings)
}

output "organization_bindings" {
  description = "Assigned organization IAM members."
  value       = keys(google_organization_iam_member.org_bindings)
}
