output "alb_dns_name" {
  value       = aws_lb.app_lb.dns_name
  description = "DNS name of the Application Load Balancer"
}

# ALB Hosted Zone ID
output "alb_zone_id" {
  value       = aws_lb.app_lb.zone_id
  description = "Hosted Zone ID for the ALB"
}

output "alb_arn" {
  value       = aws_lb.app_lb.arn
  description = "ARN of the Application Load Balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.asg.name
  description = "Name of the Auto Scaling Group"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app_tg.arn
  description = "Target Group ARN"
}

output "alb_sg_id" {
  value       = aws_security_group.alb_sg.id
  description = "ALB Security Group ID"
}

output "app_sg_id" {
  value       = aws_security_group.app_sg.id
  description = "App Security Group ID"
}
