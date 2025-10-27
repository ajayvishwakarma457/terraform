# ==============================
# Elasticache (Redis) Cluster
# ==============================

resource "aws_elasticache_subnet_group" "tanvora_cache_subnet_group" {
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cache-subnet-group"
  })
}

resource "aws_security_group" "tanvora_cache_sg" {
  name        = "${var.project_name}-cache-sg"
  description = "Allow Redis access from EC2 private subnets"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.private_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-cache-sg" })
}

resource "aws_elasticache_replication_group" "tanvora_redis" {
  replication_group_id          = "${var.project_name}-redis"
  description                   = "Redis replication group for ${var.project_name}"
  engine                        = "redis"
  engine_version                = "7.1"
  node_type                     = var.node_type
  num_cache_clusters             = var.num_nodes
  parameter_group_name          = "default.redis7"
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  port                          = 6379

  subnet_group_name             = aws_elasticache_subnet_group.tanvora_cache_subnet_group.name
  security_group_ids            = [aws_security_group.tanvora_cache_sg.id]

  tags = merge(var.common_tags, { Name = "${var.project_name}-redis" })
}
