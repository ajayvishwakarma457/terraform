variable "aws_region" {
  type        = string
  description = "AWS region (for bucket names and ARNs)"
}

variable "project_name" {
  type        = string
  description = "Project prefix for naming"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}

variable "alert_email" {
  type        = string
  description = "Email for compliance alerts (leave empty to skip subscription)"
  default     = ""
}
