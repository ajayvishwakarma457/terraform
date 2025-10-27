# -------------------------------
# VPC & Networking Resources
# -------------------------------

resource "aws_vpc" "tanvora_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-vpc" }
  )
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.tanvora_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_az
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-public-subnet" }
  )
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-private-subnet" }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "tanvora_igw" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-igw" }
  )
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-public-rt", Type = "Public" }
  )
}

# Route to Internet Gateway
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tanvora_igw.id
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP for NAT
resource "aws_eip" "tanvora_nat_eip" {
  domain = "vpc"

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-nat-eip", Type = "Public" }
  )
}

# NAT Gateway
resource "aws_nat_gateway" "tanvora_nat" {
  allocation_id = aws_eip.tanvora_nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-nat-gateway", Type = "Private" }
  )

  depends_on = [aws_internet_gateway.tanvora_igw]
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-private-rt", Type = "Private" }
  )
}

# Route from Private Subnet to NAT
resource "aws_route" "private_internet_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tanvora_nat.id
}

# Associate Private Route Table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-s3-endpoint", Type = "Gateway" }
  )
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-dynamodb-endpoint", Type = "Gateway" }
  )
}
