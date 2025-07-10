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
    prevent_destroy = false
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

data "aws_iam_policy_document" "ecr_pull_policy" {
  statement {
    sid    = "ECRPullAccess"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
      "ecr:ListImages",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRAuthorizationToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_pull_policy" {
  name        = "${var.cross_account_role_name}-ECRPullAccess"
  description = "Policy for ECR pull access"
  policy      = data.aws_iam_policy_document.ecr_pull_policy.json
}

resource "aws_iam_role_policy_attachment" "ecr_pull_access" {
  role       = aws_iam_role.cross_account_readonly.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}