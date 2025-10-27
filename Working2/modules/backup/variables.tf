variable "project_name" {
  description = "Project prefix for backup resources"
  type        = string
}

variable "common_tags" {
  description = "Standard tags for backup resources"
  type        = map(string)
}

variable "ec2_id" {
  description = "EC2 instance ID to back up"
  type        = string
}
