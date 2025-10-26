provider "aws" {
  region = "ap-south-1" # Mumbai region (change if needed)
}

# Step 1️⃣ – Create the VPC
resource "aws_vpc" "tanvora_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "tanvora-vpc"
    Project     = "Tanvora"
    Environment = "Dev"
    CreatedBy   = "Terraform"
  }
}

output "vpc_id" {
  value = aws_vpc.tanvora_vpc.id
}
