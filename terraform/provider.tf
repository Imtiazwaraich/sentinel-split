provider "aws" {
  region = var.aws_region

  # default_tags removed - IAM user lacks iam:TagRole permission
  # Tags will be applied selectively to resources that support them
}
