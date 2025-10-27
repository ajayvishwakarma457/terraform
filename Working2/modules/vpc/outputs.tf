output "vpc_id" {
  value       = aws_vpc.tanvora_vpc.id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "Public subnet ID"
}

output "private_subnet_id" {
  value       = aws_subnet.private_subnet.id
  description = "Private subnet ID"
}

output "private_route_table_id" {
  value       = aws_route_table.private_rt.id
  description = "Private route table ID"
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.tanvora_nat.id
  description = "NAT Gateway ID"
}
