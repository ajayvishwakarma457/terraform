output "backup_vault_name" {
  value       = aws_backup_vault.tanvora_vault.name
  description = "Name of the Backup Vault"
}

output "backup_plan_id" {
  value       = aws_backup_plan.tanvora_plan.id
  description = "ID of the Backup Plan"
}
