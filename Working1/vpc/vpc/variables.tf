variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Name prefix for resources"
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

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  default     = "10.0.2.0/24"
}

variable "public_az" {
  description = "Availability zone for the public subnet"
  default     = "ap-south-1a"
}

variable "private_az" {
  description = "Availability zone for the private subnet"
  default     = "ap-south-1b"
}
