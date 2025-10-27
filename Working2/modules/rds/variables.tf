variable "project_name" { type = string }
variable "common_tags" { type = map(string) }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "app_sg_id" { type = string }

variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "storage_gb" {
  type    = number
  default = 20
}

variable "max_storage_gb" {
  type    = number
  default = 100
}
