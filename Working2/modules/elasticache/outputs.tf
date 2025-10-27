output "redis_primary_endpoint" {
  value       = aws_elasticache_replication_group.tanvora_redis.primary_endpoint_address
  description = "Primary endpoint of Redis"
}

output "redis_sg_id" {
  value       = aws_security_group.tanvora_cache_sg.id
  description = "Security group ID for Redis"
}
