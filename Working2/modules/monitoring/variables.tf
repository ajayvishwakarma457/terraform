variable "aws_region" {
  type        = string
  description = "AWS region for resource naming and ARNs"
}

variable "project_name" {
  type        = string
  description = "Prefix name for project resources"
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
}

variable "alert_email" {
  type        = string
  description = "Email for receiving compliance alerts (optional)"
  default     = ""
}
