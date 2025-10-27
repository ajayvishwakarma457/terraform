variable "project_name" {
  description = "Prefix for EC2 resources"
  type        = string
}

variable "common_tags" {
  description = "Standard tags for EC2 resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "VPC ID where EC2 will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR for internal communication"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EC2 placement"
  type        = list(string)
}

variable "ec2_role_name" {
  description = "IAM role to attach to EC2"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-02d26659fd82cf299" # ✅ Amazon Linux 2 (ap-south-1)
}
