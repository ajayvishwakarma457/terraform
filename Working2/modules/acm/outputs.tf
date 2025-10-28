output "alb_cert_arn" {
  value       = aws_acm_certificate_validation.alb_valid.certificate_arn
  description = "Validated ACM certificate ARN for ALB"
}

output "cloudfront_cert_arn" {
  value       = aws_acm_certificate_validation.cf_valid.certificate_arn
  description = "Validated ACM certificate ARN for CloudFront"
}
