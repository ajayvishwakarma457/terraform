variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "hash_key" {
  description = "Primary (partition) key name"
  type        = string
}

variable "hash_key_type" {
  description = "Type of partition key (S=string, N=number)"
  type        = string
  default     = "S"
}

variable "sort_key" {
  description = "Optional sort key name"
  type        = string
  default     = ""
}

variable "sort_key_type" {
  description = "Type of sort key (S=string, N=number)"
  type        = string
  default     = "S"
}

variable "billing_mode" {
  description = "Billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}
