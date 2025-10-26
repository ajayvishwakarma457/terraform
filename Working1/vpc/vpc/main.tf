terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1️⃣ Create VPC
resource "aws_vpc" "tanvora_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# 2️⃣ Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.tanvora_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_az
  map_public_ip_on_launch = true  # Required for public subnet

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-public-subnet" }
  )
}

# 3️⃣ Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-private-subnet" }
  )
}

# 4️⃣ Internet Gateway
resource "aws_internet_gateway" "tanvora_igw" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}
