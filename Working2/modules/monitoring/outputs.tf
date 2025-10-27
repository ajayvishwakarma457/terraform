output "cloudtrail_trail_name" {
  value       = aws_cloudtrail.trail.name
  description = "Name of the CloudTrail trail"
}

output "config_bucket_name" {
  value       = aws_s3_bucket.config_bucket.bucket
  description = "Name of the AWS Config S3 bucket"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.config_alerts.arn
  description = "SNS topic ARN for compliance alerts"
}
