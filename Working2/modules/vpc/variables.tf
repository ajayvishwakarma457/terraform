variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
}

variable "public_az" {
  type        = string
  description = "Availability Zone for public subnet"
}

variable "private_az" {
  type        = string
  description = "Availability Zone for private subnet"
}
