variable "aws_region" { type = string }
variable "project_name" { type = string }
variable "common_tags" { type = map(string) }

variable "vpc_cidr" { type = string }

# Subnet CIDRs
variable "public_subnet_cidr_a" { type = string }
variable "public_subnet_cidr_b" { type = string }
variable "private_subnet_cidr_a" { type = string }
variable "private_subnet_cidr_b" { type = string }

# Availability Zones
variable "public_az_a" { type = string }
variable "public_az_b" { type = string }
variable "private_az_a" { type = string }
variable "private_az_b" { type = string }
