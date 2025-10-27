# -------------------------------
# VPC
# -------------------------------
resource "aws_vpc" "tanvora_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# -------------------------------
# Internet Gateway
# -------------------------------
resource "aws_internet_gateway" "tanvora_igw" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# -------------------------------
# Dynamic Public Subnets
# -------------------------------
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.tanvora_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-${element(var.availability_zones, count.index)}"
    Type = "Public"
  })
}

# -------------------------------
# Dynamic Private Subnets
# -------------------------------
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.tanvora_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-${element(var.availability_zones, count.index)}"
    Type = "Private"
  })
}

# -------------------------------
# Public Route Table
# -------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rt"
    Type = "Public"
  })
}

# Public Route → Internet Gateway
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tanvora_igw.id
}

# Associate Route Table with all Public Subnets
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------------
# Elastic IP for NAT
# -------------------------------
resource "aws_eip" "tanvora_nat_eip" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

# -------------------------------
# NAT Gateway (in first public subnet)
# -------------------------------
resource "aws_nat_gateway" "tanvora_nat" {
  allocation_id = aws_eip.tanvora_nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.tanvora_igw]
}

# -------------------------------
# Private Route Table
# -------------------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-rt"
    Type = "Private"
  })
}

# Private Route → NAT Gateway
resource "aws_route" "private_internet_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tanvora_nat.id
}

# Associate Route Table with all Private Subnets
resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# -------------------------------
# Gateway Endpoints (S3 & DynamoDB)
# -------------------------------
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt.id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dynamodb-endpoint"
  })
}
