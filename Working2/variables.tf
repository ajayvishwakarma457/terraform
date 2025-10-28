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
# Network Configuration (Dynamic)
# -------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs across AZs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs across AZs"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability Zones to spread subnets across"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}


variable "alert_email" {
  description = "Email to receive compliance alerts"
  type        = string
  default     = "" # set to "you@example.com" to auto-subscribe
}

variable "redis_auth_token" {
  description = "Redis auth token (do not commit to Git)"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Root domain name for Route 53 and ACM (e.g., spakcommgroup.com)"
  type        = string
}

