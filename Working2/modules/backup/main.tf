# -------------------------------
# AWS Backup Configuration (Simplified)
# -------------------------------

# 1️⃣ Create a Backup Vault
resource "aws_backup_vault" "tanvora_vault" {
  name        = "${var.project_name}-backup-vault"
  kms_key_arn = null # Optional - can add KMS encryption later

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-backup-vault" }
  )
}

# 2️⃣ IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AWS managed policy
resource "aws_iam_role_policy_attachment" "backup_policy_attach" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# 3️⃣ Create a Daily Backup Plan
resource "aws_backup_plan" "tanvora_plan" {
  name = "${var.project_name}-daily-backup-plan"

  rule {
    rule_name         = "daily-ebs-backup"
    target_vault_name = aws_backup_vault.tanvora_vault.name
    schedule          = "cron(0 2 * * ? *)"  # Every day at 2 AM UTC
    lifecycle {
      delete_after = 30                      # Retain 30 days
    }
  }

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-backup-plan" }
  )
}

# 4️⃣ Convert EC2 ID → ARN
data "aws_instance" "target" {
  instance_id = var.ec2_id
}

# 5️⃣ Select EC2 instance for backup
resource "aws_backup_selection" "tanvora_selection" {
  name         = "${var.project_name}-ec2-backup"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.tanvora_plan.id

  resources = [data.aws_instance.target.arn]

  depends_on = [aws_backup_plan.tanvora_plan]
}
