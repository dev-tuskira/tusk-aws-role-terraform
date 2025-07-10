output "cross_account_read_only_role_arn" {
  description = "ARN of the newly created cross-account read-only role"
  value       = aws_iam_role.cross_account_readonly.arn
}

output "role_name" {
  description = "Name of the cross-account read-only role"
  value       = aws_iam_role.cross_account_readonly.name
}

output "ecr_repositories_updated" {
  description = "List of ECR repositories that had policies updated"
  value       = data.aws_ecr_repositories.all.names
}