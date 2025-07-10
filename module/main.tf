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

data "aws_iam_policy_document" "ecr_pull_policy" {
  for_each = toset(data.aws_ecr_repositories.all.names)

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