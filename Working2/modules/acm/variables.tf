variable "aws_region" {
  description = "AWS region (e.g. ap-south-1)"
  type        = string
}

variable "project_name" {
  description = "Project prefix"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g. spakcommgroup.com)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
}
