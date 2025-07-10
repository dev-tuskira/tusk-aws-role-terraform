output "cross_account_read_only_role_arn" {
  description = "ARN of the newly created cross-account read-only role"
  value       = module.tuskira_cross_account.cross_account_read_only_role_arn
}

output "role_name" {
  description = "Name of the cross-account read-only role"
  value       = module.tuskira_cross_account.role_name
}

# output "ecr_repositories_updated" {
#   description = "List of ECR repositories that had policies updated"
#   value       = module.tuskira_cross_account.
# }