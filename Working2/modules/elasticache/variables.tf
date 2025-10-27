variable "project_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "private_cidr_blocks" {
  type = list(string)
}

variable "node_type" {
  type    = string
  default = "cache.t3.micro" # cost-effective dev type
}

variable "num_nodes" {
  type    = number
  default = 2
}
