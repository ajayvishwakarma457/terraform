output "cloudtrail_trail_name" {
  value       = aws_cloudtrail.trail.name
  description = "CloudTrail trail name"
}

output "config_bucket_name" {
  value       = aws_s3_bucket.config_bucket.bucket
  description = "S3 bucket where AWS Config stores data"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.config_alerts.arn
  description = "SNS topic for compliance alerts"
}
