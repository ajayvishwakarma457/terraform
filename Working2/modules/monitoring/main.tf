########################################
# MODULE: Monitoring & Compliance Stack
# Components:
#  - CloudTrail (multi-region)
#  - AWS Config
#  - SNS Alerts (NON_COMPLIANT)
#  - CloudWatch Logs integration
#  - S3 encryption + policies
########################################

data "aws_caller_identity" "me" {}

########################################
# 1️⃣ CLOUDTRAIL
########################################

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "${var.project_name}-cloudtrail-${var.aws_region}"
  tags   = merge(var.common_tags, { Name = "${var.project_name}-cloudtrail-bucket" })
}

# Enable versioning
resource "aws_s3_bucket_versioning" "cloudtrail_ver" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration { status = "Enabled" }
}

# Encrypt logs
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_sse" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Prevent public access
resource "aws_s3_bucket_public_access_block" "cloudtrail_pab" {
  bucket                  = aws_s3_bucket.cloudtrail_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AWSCloudTrailAclCheck",
        Effect = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.me.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudWatch log group for CloudTrail
resource "aws_cloudwatch_log_group" "trail_lg" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 30
  tags              = var.common_tags
}

# IAM role for CloudTrail to push logs
resource "aws_iam_role" "trail_cw_role" {
  name = "${var.project_name}-cloudtrail-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "cloudtrail.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.common_tags
}

# IAM policy for CloudTrail log publishing
resource "aws_iam_role_policy" "trail_cw_policy" {
  name = "${var.project_name}-cloudtrail-policy"
  role = aws_iam_role.trail_cw_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
      Resource = "${aws_cloudwatch_log_group.trail_lg.arn}:*"
    }]
  })
}

# CloudTrail configuration
resource "aws_cloudtrail" "trail" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.me.account_id}:log-group:${aws_cloudwatch_log_group.trail_lg.name}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.trail_cw_role.arn

  tags = merge(var.common_tags, { Name = "${var.project_name}-cloudtrail" })

  lifecycle {
    prevent_destroy = true
  }
}

########################################
# 2️⃣ AWS CONFIG
########################################

# S3 bucket for Config snapshots
resource "aws_s3_bucket" "config_bucket" {
  bucket = "${var.project_name}-config-${var.aws_region}"
  tags   = merge(var.common_tags, { Name = "${var.project_name}-config-bucket" })
}

resource "aws_s3_bucket_versioning" "config_ver" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_sse" {
  bucket = aws_s3_bucket.config_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config_pab" {
  bucket                  = aws_s3_bucket.config_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for AWS Config
resource "aws_s3_bucket_policy" "config_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AWSConfigBucketPermissionsCheck",
        Effect   = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid      = "AWSConfigBucketDelivery",
        Effect   = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.config_bucket.arn}/AWSLogs/${data.aws_caller_identity.me.account_id}/*",
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}

# IAM role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.project_name}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy" "config_inline" {
  name = "${var.project_name}-config-inline"
  role = aws_iam_role.config_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject", "s3:GetBucketAcl", "s3:ListBucket"],
        Resource = ["${aws_s3_bucket.config_bucket.arn}", "${aws_s3_bucket.config_bucket.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["config:*", "ec2:Describe*", "iam:Get*", "iam:List*", "rds:Describe*", "lambda:Get*", "lambda:List*", "s3:Get*", "s3:List*"],
        Resource = "*"
      }
    ]
  })
}

# Config recorder
resource "aws_config_configuration_recorder" "recorder" {
  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Delivery channel
resource "aws_config_delivery_channel" "channel" {
  name           = "${var.project_name}-config-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.recorder]
}

# Enable Config recorder
resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.channel]
}

# Local dependency for all rules
# locals {
#   # config_ready = [aws_config_configuration_recorder_status.status]
#   depends_on = [aws_config_configuration_recorder_status.status]
# }

########################################
# 3️⃣ SNS + EVENTBRIDGE ALERTS
########################################

resource "aws_sns_topic" "config_alerts" {
  name = "${var.project_name}-config-alerts"
  tags = merge(var.common_tags, { Name = "${var.project_name}-config-alerts" })
}

# Optional email subscription
resource "aws_sns_topic_subscription" "email_sub" {
  count     = length(var.alert_email) > 0 ? 1 : 0
  topic_arn = aws_sns_topic.config_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# EventBridge rule for non-compliance
resource "aws_cloudwatch_event_rule" "noncompliant_rule" {
  name        = "${var.project_name}-config-noncompliance"
  description = "Notify when AWS Config marks a resource NON_COMPLIANT"
  event_pattern = jsonencode({
    "source"      : ["aws.config"],
    "detail-type" : ["Config Rules Compliance Change"],
    "detail"      : { "newEvaluationResult" : { "complianceType" : ["NON_COMPLIANT"] } }
  })
  tags = var.common_tags
}

# Role for EventBridge → SNS
resource "aws_iam_role" "events_to_sns_role" {
  name = "${var.project_name}-events-sns-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy" "events_to_sns_policy" {
  name = "${var.project_name}-events-sns-policy"
  role = aws_iam_role.events_to_sns_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = "sns:Publish", Resource = aws_sns_topic.config_alerts.arn }]
  })
}

resource "aws_cloudwatch_event_target" "noncompliant_to_sns" {
  rule      = aws_cloudwatch_event_rule.noncompliant_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.config_alerts.arn
  role_arn  = aws_iam_role.events_to_sns_role.arn
}

########################################
# 4️⃣ AWS CONFIG MANAGED RULES
########################################

resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
  tags       = merge(var.common_tags, { Name = "S3 Bucket Public Read Prohibited" })
}

resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name = "s3-bucket-public-write-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
  tags       = merge(var.common_tags, { Name = "S3 Bucket Public Write Prohibited" })
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
  tags       = merge(var.common_tags, { Name = "Encrypted EBS Volumes" })
}

resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "rds-storage-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
  tags       = merge(var.common_tags, { Name = "RDS Storage Encrypted" })
}

resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
  tags       = merge(var.common_tags, { Name = "Restricted SSH Access" })
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "cloudtrail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
  tags       = merge(var.common_tags, { Name = "CloudTrail Enabled" })
}

resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"
  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  depends_on = [aws_config_configuration_recorder_status.status]
  tags       = merge(var.common_tags, { Name = "IAM Password Policy Rule" })
}
