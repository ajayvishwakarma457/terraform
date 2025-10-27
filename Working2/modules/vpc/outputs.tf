output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.tanvora_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.tanvora_nat.id
}

output "private_route_table_id" {
  description = "Private Route Table ID"
  value       = aws_route_table.private_rt.id
}
