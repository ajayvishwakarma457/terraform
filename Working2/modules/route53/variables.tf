variable "project_name" {
  description = "Project prefix"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g., spakcommgroup.com)"
  type        = string
}

variable "common_tags" {
  description = "Standard tags"
  type        = map(string)
  default     = {}
}

# ALB configuration
variable "alb_dns_name" {
  description = "DNS name of the ALB (from AWS)"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the ALB (from AWS)"
  type        = string
}

# CloudFront configuration
variable "cloudfront_domain_name" {
  description = "CloudFront domain name (output from cloudfront module)"
  type        = string
  default     = ""
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (usually Z2FDTNDATAQYW2)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "create_cdn_record" {
  description = "Create cdn.<domain> record?"
  type        = bool
  default     = true
}

# Optional API endpoint
variable "create_api_record" {
  description = "Create api.<domain> record?"
  type        = bool
  default     = false
}

variable "api_dns_name" {
  description = "DNS name for API (e.g., ALB or App Runner)"
  type        = string
  default     = ""
}

variable "api_zone_id" {
  description = "Hosted zone ID for API target"
  type        = string
  default     = ""
}
