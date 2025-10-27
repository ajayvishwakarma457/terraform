# Root outputs.tf

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_sg_id" {
  description = "RDS Security Group ID"
  value       = module.rds.rds_sg_id
}
