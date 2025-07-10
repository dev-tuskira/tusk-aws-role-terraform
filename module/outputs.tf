output "cross_account_read_only_role_arn" {
  description = "ARN of the newly created cross-account read-only role"
  value       = aws_iam_role.cross_account_readonly.arn
}

output "role_name" {
  description = "Name of the cross-account read-only role"
  value       = aws_iam_role.cross_account_readonly.name
}

output "ecr_pull_policy_arn" {
  description = "ARN of the ECR pull policy"
  value       = aws_iam_policy.ecr_pull_policy.arn
}