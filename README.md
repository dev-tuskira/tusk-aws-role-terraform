# Tuskira Cross-Account AWS IAM Role Terraform Configuration

This Terraform configuration creates a cross-account, read-only IAM role for Tuskira data collection services with modular IAM policies for ECR access.

## Overview

This configuration performs the following actions:

1. **Creates a cross-account IAM role** that can be assumed by a principal in another AWS account, secured with an External ID
2. **Attaches AWS-managed read-only policies** for comprehensive access to AWS services
3. **Creates modular IAM policies** for ECR pull access that can be attached to any role/user
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
│  │  │  • Custom ECR Pull Policy                       │    │    │
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
│  │  │ No policies │ │ No policies │ │ No policies │        │    │
│  │  │  required   │ │  required   │ │  required   │        │    │
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
- **Modular IAM Policies**: Reusable policies that can be attached to any role/user
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
                "iam:CreatePolicy",
                "iam:GetPolicy",
                "iam:AttachRolePolicy"
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

## Backend Configuration

This project uses an S3 backend to store Terraform state remotely. Before deployment, you need to configure the backend.

### Step 1: Configure S3 Backend
1. **Create an S3 bucket** in your AWS account for storing Terraform state
2. **Update backend configuration**:
   - Edit `backend.tf` file
   - Replace the empty `bucket` value with your S3 bucket name
   - Optionally, customize the `key` and `region` values

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket-name"  # Replace with your bucket name
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

3. **Optional: Enable state locking** by uncommenting the DynamoDB table configuration and creating a DynamoDB table

### Step 2: Initialize Backend
```bash
# Initialize with backend configuration
terraform init

# Or initialize with bucket name as parameter
terraform init -backend-config="bucket=your-terraform-state-bucket-name"
```

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

# Deploy only IAM policies
terraform apply -target=module.tuskira_cross_account.aws_iam_policy.ecr_pull_policy
```

## Outputs

After successful deployment, the following outputs are available:

| Output | Description |
|--------|-------------|
| `cross_account_read_only_role_arn` | ARN of the created IAM role |
| `role_name` | Name of the IAM role |
| `ecr_pull_policy_arn` | ARN of the ECR pull policy (can be attached to other roles/users) |

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

### 🚨 IAM Policy Management
- **Modular Approach**: ECR access is managed through IAM policies attached to roles/users
- **No ECR Repository Policies**: This configuration does not create ECR repository policies
- **Reusable Policies**: The created ECR pull policy can be attached to additional roles/users as needed

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

#### 1. IAM Policy Conflicts
**Error**: `EntityAlreadyExistsException: A policy called 'PolicyName' already exists`

**Solution**: 
- Import existing policy: `terraform import aws_iam_policy.ecr_pull_policy arn:aws:iam::ACCOUNT:policy/PolicyName`
- Or use a different policy name

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
terraform destroy -target=module.tuskira_cross_account.aws_iam_policy.ecr_pull_policy
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
**Architecture**: IAM Policy-Based ECR Access
**Version**: 1.0.0