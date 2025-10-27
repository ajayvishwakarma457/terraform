# -------------------------------
# Global Variables (for all modules)
# -------------------------------

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix for all resource names"
  type        = string
  default     = "tanvora"
}

variable "common_tags" {
  description = "Standard tags for all resources"
  type        = map(string)
  default = {
    Project     = "Tanvora"
    Environment = "Dev"
    Owner       = "Ajay Vishwakarma"
    ManagedBy   = "Terraform"
  }
}

# -------------------------------
# Network Configuration
# -------------------------------
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_az" {
  description = "Availability zone for public subnet"
  type        = string
  default     = "ap-south-1a"
}

variable "private_az" {
  description = "Availability zone for private subnet"
  type        = string
  default     = "ap-south-1b"
}


variable "alert_email" {
  description = "Email to receive compliance alerts"
  type        = string
  default     = "" # set to "you@example.com" to auto-subscribe
}