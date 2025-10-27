output "ec2_role_name" {
  value       = aws_iam_role.ec2_role.name
  description = "IAM Role name for EC2"
}

output "devops_group_name" {
  value       = aws_iam_group.devops_group.name
  description = "Name of IAM DevOps group"
}

output "ajay_user_name" {
  value       = aws_iam_user.ajay_user.name
  description = "IAM username created for admin"
}
