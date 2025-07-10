terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "tuskira_cross_account" {
  source = "../module"

  principal_aws_account_id   = var.principal_aws_account_id
  principal_role_name        = var.principal_role_name
  external_id               = var.external_id
  cross_account_role_name   = var.cross_account_role_name
}