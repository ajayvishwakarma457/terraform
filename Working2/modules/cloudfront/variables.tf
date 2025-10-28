variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "aws_region" {
  type        = string
  description = "Region for S3 bucket"
}

variable "common_tags" {
  type        = map(string)
  description = "Standard tags"
  default     = {}
}

variable "bucket_name" {
  type        = string
  description = "Optional explicit S3 bucket name"
  default     = ""
}

variable "domain_name" {
  type        = string
  description = "Optional custom domain (e.g., cdn.tanvora.com). If empty, use CF default domain."
  default     = ""
}

variable "alternate_names" {
  type        = list(string)
  description = "Optional SANs for the certificate (e.g., ['static.tanvora.com'])"
  default     = []
}

variable "route53_zone_id" {
  type        = string
  description = "Optional hosted zone ID to auto-create ACM DNS validation records"
  default     = ""
}

variable "price_class" {
  type        = string
  description = "CloudFront price class"
  default     = "PriceClass_100"
}

variable "cache_policy_id" {
  type        = string
  description = "Optional custom cache policy ID (else uses AWS Managed CachingOptimized)"
  default     = ""
}

variable "origin_request_policy_id" {
  type        = string
  description = "Optional custom origin request policy ID (else uses AWS Managed CORS-S3Origin)"
  default     = ""
}

variable "response_headers_policy_id" {
  type        = string
  description = "Optional Response Headers Policy ID"
  default     = ""
}

variable "create_test_index" {
  type        = bool
  description = "Upload a basic index.html for quick smoke test"
  default     = true
}
