# -------------------------------
# Provider & Global Config
# -------------------------------

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1" # Mumbai region
}

variable "project_name" {
  description = "Project name prefix for tagging"
  type        = string
  default     = "tanvora"
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "Tanvora"
    Environment = "Dev"
    Owner       = "Ajay Vishwakarma"
    ManagedBy   = "Terraform"
  }
}

# -------------------------------
# VPC & Subnet Config
# -------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_az" {
  description = "Availability Zone for the public subnet"
  type        = string
  default     = "ap-south-1a"
}

variable "private_az" {
  description = "Availability Zone for the private subnet"
  type        = string
  default     = "ap-south-1b"
}

variable "alert_email" {
  description = "Email address for AWS Config compliance alerts"
  type        = string
  default     = "your.email@example.com"  # 👈 Replace with your email
}

