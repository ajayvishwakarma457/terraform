resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  }
}


resource "aws_db_instance" "this" {
  identifier              = "${var.project}-${var.environment}-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp2"
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.db.id]

  username                = "admin"
  password                = aws_secretsmanager_secret_version.db_password_version.secret_string
  skip_final_snapshot     = true
  multi_az                = true

  tags = {
    Name = "${var.project}-${var.environment}-db"
  }
}

