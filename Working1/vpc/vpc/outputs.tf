output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.tanvora_vpc.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.tanvora_vpc.cidr_block
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private_subnet.id
}

output "public_subnet_cidr" {
  description = "CIDR block of public subnet"
  value       = aws_subnet.public_subnet.cidr_block
}

output "private_subnet_cidr" {
  description = "CIDR block of private subnet"
  value       = aws_subnet.private_subnet.cidr_block
}
