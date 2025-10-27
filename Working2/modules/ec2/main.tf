# -------------------------------
# EC2 Instance Configuration
# -------------------------------

# 1️⃣ Security Group for Private EC2
resource "aws_security_group" "ec2_private_sg" {
  name        = "${var.project_name}-private-sg"
  description = "Security group for private EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all traffic within the VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow outbound internet access via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-private-sg" }
  )
}

# 2️⃣ IAM Instance Profile (attach the IAM Role from IAM module)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = var.ec2_role_name
}

# 3️⃣ Private EC2 Instance (via SSM)
resource "aws_instance" "private_ec2" {
  ami                         = var.ec2_ami
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_ids[0]
  iam_instance_profile         = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.ec2_private_sg.id]
  associate_public_ip_address = false

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-private-ec2" }
  )
}
