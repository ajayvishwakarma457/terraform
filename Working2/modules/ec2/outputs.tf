output "private_ec2_id" {
  value       = aws_instance.private_ec2.id
  description = "ID of the private EC2 instance"
}

output "private_ec2_private_ip" {
  value       = aws_instance.private_ec2.private_ip
  description = "Private IP address of the EC2 instance"
}

output "ec2_sg_id" {
  value       = aws_security_group.ec2_private_sg.id
  description = "Security group ID for private EC2"
}
