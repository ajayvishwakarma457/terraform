# -------------------------------
# VPC & Multi-AZ Networking
# -------------------------------

resource "aws_vpc" "tanvora_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, { Name = "${var.project_name}-vpc" })
}

# ========================
# PUBLIC SUBNETS (AZ-A & AZ-B)
# ========================

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.tanvora_vpc.id
  cidr_block              = var.public_subnet_cidr_a
  availability_zone       = var.public_az_a
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, { Name = "${var.project_name}-public-a" })
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.tanvora_vpc.id
  cidr_block              = var.public_subnet_cidr_b
  availability_zone       = var.public_az_b
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, { Name = "${var.project_name}-public-b" })
}

# ========================
# PRIVATE SUBNETS (AZ-A & AZ-B)
# ========================

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = var.private_az_a

  tags = merge(var.common_tags, { Name = "${var.project_name}-private-a" })
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = var.private_az_b

  tags = merge(var.common_tags, { Name = "${var.project_name}-private-b" })
}

# ========================
# INTERNET GATEWAY & ROUTING
# ========================

resource "aws_internet_gateway" "tanvora_igw" {
  vpc_id = aws_vpc.tanvora_vpc.id
  tags   = merge(var.common_tags, { Name = "${var.project_name}-igw" })
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id
  tags   = merge(var.common_tags, { Name = "${var.project_name}-public-rt", Type = "Public" })
}

# Route to Internet Gateway
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tanvora_igw.id
}

# Associate Route Table with both public subnets
resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# ========================
# NAT GATEWAY (in AZ-A)
# ========================

resource "aws_eip" "tanvora_nat_eip" {
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "${var.project_name}-nat-eip" })
}

resource "aws_nat_gateway" "tanvora_nat" {
  allocation_id = aws_eip.tanvora_nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = merge(var.common_tags, { Name = "${var.project_name}-nat" })
  depends_on = [aws_internet_gateway.tanvora_igw]
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id
  tags   = merge(var.common_tags, { Name = "${var.project_name}-private-rt", Type = "Private" })
}

# Route from Private Subnets to NAT
resource "aws_route" "private_internet_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tanvora_nat.id
}

# Associate Private Route Table with both private subnets
resource "aws_route_table_association" "private_assoc_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}

# ========================
# VPC ENDPOINTS
# ========================

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = merge(var.common_tags, { Name = "${var.project_name}-s3-endpoint" })
}

resource "aws_vpc_endpoint" "dynamodb_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = merge(var.common_tags, { Name = "${var.project_name}-dynamodb-endpoint" })
}
