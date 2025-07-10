variable "principal_aws_account_id" {
  description = "The AWS Account ID of the principal allowed to assume the role"
  type        = string
}

variable "principal_role_name" {
  description = "The name of the role in the principal account that will assume this role"
  type        = string
}

variable "external_id" {
  description = "The external ID required to assume the role, providing a layer of security"
  type        = string
  sensitive   = true
}

variable "cross_account_role_name" {
  description = "The name for the created cross-account read-only IAM role"
  type        = string
}