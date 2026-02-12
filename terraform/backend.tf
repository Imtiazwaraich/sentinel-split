# Terraform backend configuration
# Uncomment and configure if you have S3 bucket access for remote state
# 
# terraform {
#   backend "s3" {
#     bucket         = "sentinel-split-terraform-state"
#     key            = "sentinel/terraform.tfstate"
#     region         = "us-west-2"
#     encrypt        = true
#     dynamodb_table = "sentinel-terraform-locks"
#   }
# }
#
# For this challenge, using local backend is acceptable.
# In production, always use remote state with locking.
