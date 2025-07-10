# Tuskira Cross-Account AWS IAM Role Terraform Configuration

This Terraform configuration creates a cross-account, read-only IAM role for Tuskira data collection services with ECR repository access policies.

## Overview

This configuration performs the following actions:

1. **Creates a cross-account IAM role** that can be assumed by a principal in another AWS account, secured with an External ID
2. **Attaches AWS-managed read-only policies** for comprehensive access to AWS services
3. **Configures ECR repository policies** to allow cross-account image pulling
4. **Implements lifecycle protection** to prevent accidental deletion

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Target Account                           │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              Tuskira Cross-Account Role                 │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │               Managed Policies                  │    │    │
│  │  │  • ReadOnlyAccess                               │    │    │
│  │  │  • AWSSecurityHubReadOnlyAccess                 │    │    │
│  │  │  • AmazonEC2ContainerRegistryReadOnly           │    │    │
│  │  │  • AmazonInspector2ReadOnlyAccess               │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  │                                                         │    │
│  │  Trust Policy: External ID + Principal Account          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                 ECR Repositories                        │    │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        │    │
│  │  │   Repo 1    │ │   Repo 2    │ │   Repo N    │        │    │
│  │  │             │ │             │ │             │        │    │
│  │  │Cross-account│ │Cross-account│ │Cross-account│        │    │
│  │  │pull policy  │ │pull policy  │ │pull policy  │        │    │
│  │  └─────────────┘ └─────────────┘ └─────────────┘        │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                 ▲
                                 │ Assumes Role
                                 │
┌─────────────────────────────────────────────────────────────────┐
│                      Principal Account                          │
│                     (324037289929)                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │            tuskira-data-collection                      │    │
│  │                     Role                                │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
tusk-aws-cross-account-terraform/
├── README.md                    # This file
├── main/                        # Main configuration directory
│   ├── main.tf                  # Provider config and module call
│   ├── variables.tf              # Input variable definitions
│   ├── terraform.tfvars          # Variable values
│   └── outputs.tf                # Output definitions
└── module/                       # Reusable module
    ├── main.tf                   # Core resources
    ├── variables.tf              # Module variable definitions
    └── outputs.tf                # Module outputs
```

## Features

### 🔐 Security Features
- **External ID Authentication**: Uses `tuskira20250401` external ID for secure cross-account access
- **Principle of Least Privilege**: Only read-only access permissions
- **Account-specific Trust Policy**: Limited to specific principal account and role

### 📊 AWS Service Coverage
- **General AWS Resources**: ReadOnlyAccess policy
- **Security Hub**: Read access to security findings
- **ECR**: Container registry read access and image pull permissions
- **Inspector v2**: Vulnerability scanning results for EC2 and Lambda

### 🛡️ Operational Safety
- **Lifecycle Protection**: Prevents accidental deletion of the IAM role
- **Declarative ECR Policies**: Terraform manages all ECR repository policies
- **Consistent Configuration**: Version-controlled infrastructure as code

## Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- Access to the target AWS account with IAM permissions

### Required AWS Permissions
The user/role deploying this configuration needs the following permissions in the target account:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:GetRole",
                "iam:ListAttachedRolePolicies",
                "iam:TagRole",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:SetRepositoryPolicy"
            ],
            "Resource": "*"
        }
    ]
}
```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region to deploy resources | `us-east-1` | No |
| `principal_aws_account_id` | AWS Account ID of the principal | `324037289929` | No |
| `principal_role_name` | Name of the role in principal account | `tuskira-data-collection` | No |
| `external_id` | External ID for assume role security | `tuskira20250401` | No |
| `cross_account_role_name` | Name of the created IAM role | `TuskiraCrossAccountReadOnlyRole` | No |

## Deployment

### Step 1: Clone and Navigate
```bash
git clone <repository-url>
cd tusk-aws-cross-account-terraform/main
```

### Step 2: Initialize Terraform
```bash
terraform init
```

### Step 3: Review Configuration
```bash
terraform plan
```

### Step 4: Deploy
```bash
terraform apply
```

### Step 5: Confirm Deployment
```bash
terraform output
```

## Usage Examples

### Basic Deployment
```bash
cd main/
terraform init
terraform plan
terraform apply
```

### Custom Configuration
Create a custom `.tfvars` file:

```hcl
# custom.tfvars
aws_region                = "us-west-2"
cross_account_role_name   = "MyCustomTuskiraRole"
external_id              = "my-custom-external-id"
```

Deploy with custom configuration:
```bash
terraform apply -var-file="custom.tfvars"
```

### Targeting Specific Resources
```bash
# Deploy only the IAM role
terraform apply -target=module.tuskira_cross_account.aws_iam_role.cross_account_readonly

# Deploy only ECR policies
terraform apply -target=module.tuskira_cross_account.aws_ecr_repository_policy.cross_account_pull
```

## Outputs

After successful deployment, the following outputs are available:

| Output | Description |
|--------|-------------|
| `cross_account_read_only_role_arn` | ARN of the created IAM role |
| `role_name` | Name of the IAM role |
| `ecr_repositories_updated` | List of ECR repositories with updated policies |

### Retrieving Outputs
```bash
# Get all outputs
terraform output

# Get specific output
terraform output cross_account_read_only_role_arn

# Get output in JSON format
terraform output -json
```

## Important Considerations

### 🚨 ECR Policy Management
- **Complete Policy Ownership**: This Terraform configuration will **overwrite** any existing ECR repository policies
- **New Repositories**: If you create new ECR repositories after deployment, run `terraform apply` again to update policies
- **Policy Conflicts**: Remove any manually created ECR policies before deployment

### 🔄 State Management
- **Remote State**: Consider using remote state storage (S3 + DynamoDB) for production deployments
- **State Locking**: Use state locking to prevent concurrent modifications
- **Backup**: Regularly backup your Terraform state file

### 🛡️ Security Best Practices
- **External ID Rotation**: Regularly rotate the external ID
- **Least Privilege**: Review attached policies periodically
- **Monitoring**: Set up CloudTrail logging for role usage
- **Access Review**: Regularly audit cross-account access

## Troubleshooting

### Common Issues

#### 1. ECR Repository Policy Conflicts
**Error**: `ResourceInUseException: The repository policy for repository 'xxx' is being used by another request`

**Solution**: 
- Wait a few minutes and retry
- Check for other Terraform runs or manual policy changes

#### 2. Role Already Exists
**Error**: `EntityAlreadyExistsException: Role with name TuskiraCrossAccountReadOnlyRole already exists`

**Solution**:
- Import existing role: `terraform import module.tuskira_cross_account.aws_iam_role.cross_account_readonly TuskiraCrossAccountReadOnlyRole`
- Or use a different role name

#### 3. Insufficient Permissions
**Error**: `AccessDenied: User/Role doesn't have permission to perform iam:CreateRole`

**Solution**:
- Ensure deploying user has required IAM permissions
- Check AWS credentials and region configuration

### Validation Commands
```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check

# Plan with detailed logging
TF_LOG=DEBUG terraform plan

# Verify AWS credentials
aws sts get-caller-identity
```

## Maintenance

### Regular Tasks
1. **Update Terraform**: Keep Terraform and providers updated
2. **Review Policies**: Periodically review attached AWS managed policies
3. **Rotate Credentials**: Rotate external ID and access keys
4. **Monitor Usage**: Check CloudTrail logs for role usage

### Updates and Upgrades
```bash
# Update provider versions
terraform init -upgrade

# Check for configuration drift
terraform plan

# Apply any necessary changes
terraform apply
```

## Cleanup

### Removing Resources
```bash
# Destroy all resources
terraform destroy

# Destroy specific resources
terraform destroy -target=module.tuskira_cross_account.aws_ecr_repository_policy.cross_account_pull
```

⚠️ **Warning**: The IAM role has `prevent_destroy = true` lifecycle rule. To destroy it:
1. Comment out the `lifecycle` block in `module/main.tf`
2. Run `terraform apply`
3. Run `terraform destroy`

## Support and Contributing

### Getting Help
- Review AWS documentation for IAM and ECR
- Check Terraform documentation for AWS provider
- Use `terraform plan` to understand changes before applying

### Contributing
1. Follow Terraform best practices
2. Test changes in a development environment
3. Update documentation for any configuration changes
4. Use meaningful commit messages

## License

This configuration is provided as-is for Tuskira cross-account access setup. Review and modify according to your organization's security requirements.

---

**Generated with**: Terraform AWS Provider
**Last Updated**: 2025-07-10
**Version**: 1.0.0