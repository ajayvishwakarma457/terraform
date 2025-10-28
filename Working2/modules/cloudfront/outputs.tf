output "s3_bucket_name" {
  value       = aws_s3_bucket.cdn_bucket.id
  description = "Name of the S3 bucket backing the CDN"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.cdn.id
  description = "CloudFront distribution ID"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "CloudFront domain name (use if no custom domain)"
}

output "acm_certificate_arn" {
  value       = try(aws_acm_certificate.cert[0].arn, null)
  description = "ACM certificate ARN (if custom domain provided)"
}

# If you didn't pass route53_zone_id, you'll get these to create manually in Route53
output "acm_dns_validation_records" {
  description = "CNAME records required for ACM validation when not auto-created"
  value       = var.domain_name != "" && var.route53_zone_id == "" ? aws_acm_certificate.cert[0].domain_validation_options : []
}
