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

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.tanvora_igw.id
}

output "public_route_table_id" {
  description = "Route Table ID for the Public Subnet"
  value       = aws_route_table.public_rt.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.tanvora_nat.id
}

output "nat_eip" {
  description = "Elastic IP for NAT Gateway"
  value       = aws_eip.tanvora_nat_eip.public_ip
}

output "private_route_table_id" {
  description = "Route Table ID for Private Subnet"
  value       = aws_route_table.private_rt.id
}

output "s3_gateway_endpoint_id" {
  description = "ID of the S3 VPC Gateway Endpoint"
  value       = aws_vpc_endpoint.s3_gateway.id
}

output "dynamodb_gateway_endpoint_id" {
  description = "ID of the DynamoDB VPC Gateway Endpoint"
  value       = aws_vpc_endpoint.dynamodb_gateway.id
}

