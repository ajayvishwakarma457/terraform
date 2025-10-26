terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1️⃣ Create VPC
resource "aws_vpc" "tanvora_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# 2️⃣ Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.tanvora_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_az
  map_public_ip_on_launch = true  # Required for public subnet

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-public-subnet" }
  )
}

# 3️⃣ Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-private-subnet" }
  )
}

# 4️⃣ Internet Gateway
resource "aws_internet_gateway" "tanvora_igw" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# 5️⃣ Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public-rt"
      Type = "Public"
    }
  )
}

# 6️⃣ Route to Internet Gateway
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tanvora_igw.id
}

# 7️⃣ Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 8️⃣ Elastic IP for NAT Gateway
resource "aws_eip" "tanvora_nat_eip" {
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-nat-eip"
      Type = "Public"
    }
  )
}

# 9️⃣ NAT Gateway (in Public Subnet)
resource "aws_nat_gateway" "tanvora_nat" {
  allocation_id = aws_eip.tanvora_nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-nat-gateway"
      Type = "Private"
    }
  )

  depends_on = [aws_internet_gateway.tanvora_igw]
}

# 🔟 Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private-rt"
      Type = "Private"
    }
  )
}

# 1️⃣1️⃣ Route from Private Subnet to NAT Gateway
resource "aws_route" "private_internet_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tanvora_nat.id
}

# 1️⃣2️⃣ Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# 1️⃣3️⃣ S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private_rt.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-s3-endpoint"
      Type = "Gateway"
    }
  )
}

# 1️⃣4️⃣ DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private_rt.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-dynamodb-endpoint"
      Type = "Gateway"
    }
  )
}

# 🧱 1️⃣5️⃣ Security Group for Interface Endpoints (NEW)
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "${var.project_name}-vpc-endpoints-sg"
  description = "Allow HTTPS (443) within the VPC for Interface Endpoints"
  vpc_id      = aws_vpc.tanvora_vpc.id

  ingress {
    description = "Allow HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.tanvora_vpc.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-vpc-endpoints-sg" }
  )
}

# 1️⃣6️⃣ Interface Endpoint for Systems Manager (SSM)
resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id             = aws_vpc.tanvora_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ssm-endpoint"
      Type = "Interface"
    }
  )
}

# 1️⃣7️⃣ Interface Endpoint for EC2 Messages
resource "aws_vpc_endpoint" "ec2_messages_endpoint" {
  vpc_id             = aws_vpc.tanvora_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ec2messages-endpoint"
      Type = "Interface"
    }
  )
}

# 1️⃣8️⃣ Interface Endpoint for SSM Messages
resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id             = aws_vpc.tanvora_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ssmmessages-endpoint"
      Type = "Interface"
    }
  )
}

# 1️⃣9️⃣ Interface Endpoint for CloudWatch Logs
resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  vpc_id             = aws_vpc.tanvora_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cloudwatch-endpoint"
      Type = "Interface"
    }
  )
}


# 2️⃣0️⃣ CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.project_name}/flowlogs"
  retention_in_days = 30
  tags              = var.common_tags
}

# 2️⃣1️⃣ IAM Role for Flow Logs to write to CloudWatch
resource "aws_iam_role" "vpc_flow" {
  name = "${var.project_name}-vpc-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "vpc-flow-logs.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

# 2️⃣2️⃣ IAM Policy for Flow Logs
resource "aws_iam_role_policy" "vpc_flow" {
  name = "${var.project_name}-vpc-flowlogs-policy"
  role = aws_iam_role.vpc_flow.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# 2️⃣3️⃣ Enable VPC Flow Logs (AWS Provider v5.x Syntax)
resource "aws_flow_log" "tanvora_vpc_flow" {
  vpc_id               = aws_vpc.tanvora_vpc.id
  traffic_type         = "ALL"                       # can be ACCEPT, REJECT, or ALL
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow.arn
  iam_role_arn         = aws_iam_role.vpc_flow.arn

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc-flowlogs"
      Type = "Monitoring"
    }
  )
}
