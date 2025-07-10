# Terraform Backend Configuration
# Configure S3 backend for storing Terraform state
# 
# To use this backend:
# 1. Create an S3 bucket in your AWS account
# 2. Replace "YOUR_BUCKET_NAME" with your actual bucket name
# 3. Optionally, customize the key path and region
# 4. Run 'terraform init' to initialize the backend
#
# Example initialization command:
# terraform init -backend-config="bucket=my-terraform-state-bucket"

terraform {
  backend "s3" {
    bucket = ""  # Replace with your S3 bucket name
    key    = "terraform.tfstate"
    region = "us-east-1"  # Change to your preferred region
    
    # Optional: Enable state locking with DynamoDB
    # dynamodb_table = "terraform-state-lock"
    
    # Optional: Enable server-side encryption
    # encrypt = true
  }
}