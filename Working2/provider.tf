terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tanvora-terraform-state" # <-- create this S3 bucket manually first
    key            = "infra/terraform.tfstate" # <-- state file path in bucket
    region         = "ap-south-1"              # <-- same as your region
    dynamodb_table = "tanvora-terraform-lock"  # <-- create DynamoDB table manually first
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
