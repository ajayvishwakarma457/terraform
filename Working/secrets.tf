resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project}-${var.environment}-db-password"
  description = "RDS master password for ${var.project}-${var.environment}"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = "StrongPassword123!" # 🔹 Replace with secure password
}

resource "aws_iam_policy" "db_secret_read" {
  name        = "${var.project}-${var.environment}-db-secret-read"
  description = "Allow reading DB password from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}

# resource "aws_iam_role_policy_attachment" "db_secret_attach" {
#   role       = aws_iam_role.ec2_ssm_role.name
#   policy_arn = aws_iam_policy.db_secret_read.arn
# }
