output "vpc_id" {
  value       = aws_vpc.tanvora_vpc.id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "Public Subnet ID"
}

output "private_subnet_id" {
  value       = aws_subnet.private_subnet.id
  description = "Private Subnet ID"
}
