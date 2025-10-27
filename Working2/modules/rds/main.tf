# ==============================
# RDS Database (MySQL example)
# ==============================

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.common_tags, { Name = "${var.project_name}-rds-subnet-group" })
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow DB access from app servers"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL from App SG"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-rds-sg" })
}

resource "aws_db_instance" "rds_instance" {
  identifier              = "${var.project_name}-rds"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.instance_class
  allocated_storage       = var.storage_gb
  max_allocated_storage   = var.max_storage_gb
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  multi_az                = true
  backup_retention_period = 7
  storage_encrypted       = true
  deletion_protection     = false
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false

  tags = merge(var.common_tags, { Name = "${var.project_name}-rds" })
}
