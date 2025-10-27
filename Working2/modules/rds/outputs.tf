output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.rds_instance.address
}

output "rds_sg_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds_sg.id
}
