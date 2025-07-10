data "aws_iam_policy_document" "cross_account_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.principal_aws_account_id}:role/${var.principal_role_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "cross_account_readonly" {
  name               = var.cross_account_role_name
  assume_role_policy = data.aws_iam_policy_document.cross_account_assume_role.json

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Description = "Cross-account read-only role for Tuskira data collection"
    Purpose     = "Tuskira Cross-Account Access"
  }
}

resource "aws_iam_role_policy_attachment" "readonly_access" {
  role       = aws_iam_role.cross_account_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "securityhub_readonly" {
  role       = aws_iam_role.cross_account_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSecurityHubReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.cross_account_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "inspector_readonly" {
  role       = aws_iam_role.cross_account_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonInspector2ReadOnlyAccess"
}

data "aws_ecr_repositories" "all" {}

data "aws_ecr_repository_policy" "existing" {
  for_each = toset(data.aws_ecr_repositories.all.names)
  
  repository_name = each.key
}

locals {
  existing_policies = {
    for repo in data.aws_ecr_repositories.all.names : repo => try(
      jsondecode(data.aws_ecr_repository_policy.existing[repo].policy),
      { Version = "2012-10-17", Statement = [] }
    )
  }
}

data "aws_iam_policy_document" "ecr_pull_policy" {
  for_each = toset(data.aws_ecr_repositories.all.names)

  # Preserve existing statements
  dynamic "statement" {
    for_each = try(local.existing_policies[each.key].Statement, [])
    content {
      sid           = try(statement.value.Sid, null)
      effect        = try(statement.value.Effect, "Allow")
      actions       = try(statement.value.Action, [])
      not_actions   = try(statement.value.NotAction, [])
      resources     = try(statement.value.Resource, [])
      not_resources = try(statement.value.NotResource, [])
      
      dynamic "principals" {
        for_each = try(statement.value.Principal, {}) != {} ? [statement.value.Principal] : []
        content {
          type        = try(principals.value.AWS != null ? "AWS" : keys(principals.value)[0], "*")
          identifiers = try(principals.value.AWS != null ? (
            is_string(principals.value.AWS) ? [principals.value.AWS] : principals.value.AWS
          ) : (
            is_string(principals.value[keys(principals.value)[0]]) ? 
            [principals.value[keys(principals.value)[0]]] : 
            principals.value[keys(principals.value)[0]]
          ), ["*"])
        }
      }
      
      dynamic "condition" {
        for_each = try(statement.value.Condition, {})
        content {
          test     = keys(condition.value)[0]
          variable = keys(condition.value[keys(condition.value)[0]])[0]
          values   = condition.value[keys(condition.value)[0]][keys(condition.value[keys(condition.value)[0]])[0]]
        }
      }
    }
  }

  # Add new cross-account statement
  statement {
    sid    = "CrossAccountPullFromDataCollectionRole"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
      "ecr:ListImages",
      "ecr:BatchCheckLayerAvailability"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.principal_aws_account_id}:role/${var.principal_role_name}"]
    }
  }
}

resource "aws_ecr_repository_policy" "cross_account_pull" {
  for_each = toset(data.aws_ecr_repositories.all.names)

  repository = each.key
  policy     = data.aws_iam_policy_document.ecr_pull_policy[each.key].json
}