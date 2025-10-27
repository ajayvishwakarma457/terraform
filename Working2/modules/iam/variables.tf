variable "project_name" {
  description = "Project prefix for IAM resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags for IAM resources"
  type        = map(string)
}
