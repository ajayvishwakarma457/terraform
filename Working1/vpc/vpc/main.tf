terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1️⃣ Create VPC
resource "aws_vpc" "tanvora_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# 2️⃣ Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.tanvora_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_az
  map_public_ip_on_launch = true  # Required for public subnet

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-public-subnet" }
  )
}

# 3️⃣ Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_az

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-private-subnet" }
  )
}

# 4️⃣ Internet Gateway
resource "aws_internet_gateway" "tanvora_igw" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# 5️⃣ Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public-rt"
      Type = "Public"
    }
  )
}

# 6️⃣ Route to Internet Gateway
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tanvora_igw.id
}

# 7️⃣ Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 8️⃣ Elastic IP for NAT Gateway
resource "aws_eip" "tanvora_nat_eip" {
  domain = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-nat-eip"
      Type = "Public"
    }
  )
}

# 9️⃣ NAT Gateway (in Public Subnet)
resource "aws_nat_gateway" "tanvora_nat" {
  allocation_id = aws_eip.tanvora_nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-nat-gateway"
      Type = "Private"
    }
  )

  depends_on = [aws_internet_gateway.tanvora_igw]
}

# 🔟 Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.tanvora_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private-rt"
      Type = "Private"
    }
  )
}

# 1️⃣1️⃣ Route from Private Subnet to NAT Gateway
resource "aws_route" "private_internet_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tanvora_nat.id
}

# 1️⃣2️⃣ Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# 1️⃣3️⃣ S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private_rt.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-s3-endpoint"
      Type = "Gateway"
    }
  )
}

# 1️⃣4️⃣ DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb_gateway" {
  vpc_id            = aws_vpc.tanvora_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private_rt.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-dynamodb-endpoint"
      Type = "Gateway"
    }
  )
}

# 🧱 1️⃣5️⃣ Security Group for Interface Endpoints (NEW)
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "${var.project_name}-vpc-endpoints-sg"
  description = "Allow HTTPS (443) within the VPC for Interface Endpoints"
  vpc_id      = aws_vpc.tanvora_vpc.id

  ingress {
    description = "Allow HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.tanvora_vpc.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-vpc-endpoints-sg" }
  )
}

# 1️⃣6️⃣ Interface Endpoint for Systems Manager (SSM)
resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id             = aws_vpc.tanvora_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ssm-endpoint"
      Type = "Interface"
    }
  )
}

# 1️⃣7️⃣ Interface Endpoint for EC2 Messages
resource "aws_vpc_endpoint" "ec2_messages_endpoint" {
  vpc_id             = aws_vpc.tanvora_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ec2messages-endpoint"
      Type = "Interface"
    }
  )
}

# 1️⃣8️⃣ Interface Endpoint for SSM Messages
resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id             = aws_vpc.tanvora_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ssmmessages-endpoint"
      Type = "Interface"
    }
  )
}

# 1️⃣9️⃣ Interface Endpoint for CloudWatch Logs
resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  vpc_id             = aws_vpc.tanvora_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.vpc_endpoints_sg.id]

  private_dns_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cloudwatch-endpoint"
      Type = "Interface"
    }
  )
}


# 2️⃣0️⃣ CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.project_name}/flowlogs"
  retention_in_days = 30
  tags              = var.common_tags
}

# 2️⃣1️⃣ IAM Role for Flow Logs to write to CloudWatch
resource "aws_iam_role" "vpc_flow" {
  name = "${var.project_name}-vpc-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "vpc-flow-logs.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

# 2️⃣2️⃣ IAM Policy for Flow Logs
resource "aws_iam_role_policy" "vpc_flow" {
  name = "${var.project_name}-vpc-flowlogs-policy"
  role = aws_iam_role.vpc_flow.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# 2️⃣3️⃣ Enable VPC Flow Logs (AWS Provider v5.x Syntax)
resource "aws_flow_log" "tanvora_vpc_flow" {
  vpc_id               = aws_vpc.tanvora_vpc.id
  traffic_type         = "ALL"                       # can be ACCEPT, REJECT, or ALL
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow.arn
  iam_role_arn         = aws_iam_role.vpc_flow.arn

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc-flowlogs"
      Type = "Monitoring"
    }
  )
}

# 2️⃣4️⃣ S3 Bucket for VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket = "${var.project_name}-vpc-flowlogs-${var.aws_region}"

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-vpc-flowlogs-bucket" }
  )
}

# 2️⃣5️⃣ Enable Versioning (best practice for audit)
resource "aws_s3_bucket_versioning" "vpc_flow_logs_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 2️⃣6️⃣ Enable Server-Side Encryption (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_sse" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2️⃣7️⃣ Lifecycle Policy (auto-archive to Glacier and delete after 365 days)
resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  rule {
    id     = "archive-and-delete-old-logs"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# 2️⃣8️⃣ Allow VPC Flow Logs Service to Write to the Bucket
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "vpc_flow_logs_policy" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite",
        Effect    = "Allow",
        Principal = { Service = "delivery.logs.amazonaws.com" },
        Action    = ["s3:PutObject"],
        Resource  = "${aws_s3_bucket.vpc_flow_logs_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck",
        Effect    = "Allow",
        Principal = { Service = "delivery.logs.amazonaws.com" },
        Action    = ["s3:GetBucketAcl"],
        Resource  = aws_s3_bucket.vpc_flow_logs_bucket.arn
      }
    ]
  })
}

# 2️⃣9️⃣ Create a Separate Flow Log → S3 Destination
resource "aws_flow_log" "tanvora_vpc_flow_s3" {
  vpc_id               = aws_vpc.tanvora_vpc.id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.vpc_flow_logs_bucket.arn

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc-flowlogs-s3"
      Type = "Monitoring"
    }
  )
}


# 3️⃣0️⃣ S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "${var.project_name}-cloudtrail-${var.aws_region}"

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-cloudtrail-bucket" }
  )
}

# 3️⃣1️⃣ Enable Versioning (recommended for audit)
resource "aws_s3_bucket_versioning" "cloudtrail_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3️⃣2️⃣ Encrypt CloudTrail Logs (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_sse" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3️⃣3️⃣ Allow CloudTrail service to write logs to the bucket
# data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 3️⃣4️⃣ CloudWatch Log Group (for real-time CloudTrail monitoring)
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 30
  tags              = var.common_tags
}

# 3️⃣5️⃣ IAM Role for CloudTrail → CloudWatch
resource "aws_iam_role" "cloudtrail" {
  name = "${var.project_name}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "cloudtrail" {
  name = "${var.project_name}-cloudtrail-policy"
  role = aws_iam_role.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# 3️⃣6️⃣ Create the CloudTrail
resource "aws_cloudtrail" "tanvora_trail" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  # ✅ Fix: Provide full ARN manually using region + account_id
  cloud_watch_logs_group_arn = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail.arn

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-cloudtrail" }
  )
}



# 3️⃣7️⃣ S3 Bucket for AWS Config
resource "aws_s3_bucket" "config_bucket" {
  bucket = "${var.project_name}-config-${var.aws_region}"

  tags = merge(
    var.common_tags,
    { Name = "${var.project_name}-config-bucket" }
  )
}

# 3️⃣8️⃣ Enable Versioning (to keep config history)
resource "aws_s3_bucket_versioning" "config_versioning" {
  bucket = aws_s3_bucket.config_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3️⃣9️⃣ Enable Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "config_sse" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4️⃣0️⃣ Allow AWS Config to Write to the S3 Bucket
# data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "config_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck",
        Effect    = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid       = "AWSConfigBucketDelivery",
        Effect    = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.config_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 4️⃣1️⃣ IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "config.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

# 4️⃣2️⃣ IAM Policy for AWS Config Role
resource "aws_iam_role_policy" "config_role_policy" {
  name = "${var.project_name}-config-policy"
  role = aws_iam_role.config_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",
          "config:*",
          "ec2:Describe*",
          "iam:List*",
          "iam:Get*",
          "rds:Describe*",
          "s3:ListAllMyBuckets",
          "lambda:List*",
          "lambda:Get*"
        ],
        Resource = "*"
      }
    ]
  })
}

# 4️⃣3️⃣ Create AWS Config Recorder
resource "aws_config_configuration_recorder" "tanvora_config" {
  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# 4️⃣4️⃣ Delivery Channel (S3 + optional SNS)
resource "aws_config_delivery_channel" "tanvora_channel" {
  name           = "${var.project_name}-config-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.tanvora_config]
}

# 4️⃣5️⃣ Enable AWS Config Recorder
resource "aws_config_configuration_recorder_status" "tanvora_config_status" {
  name       = aws_config_configuration_recorder.tanvora_config.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.tanvora_channel]
}

# 4️⃣6️⃣ AWS Config Managed Rules
# ----------------------------------------------------
# 1️⃣ Ensure S3 Buckets are not publicly readable
resource "aws_config_config_rule" "s3_public_read" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.tanvora_config_status]

  tags = merge(var.common_tags, { Name = "S3 Public Read Prohibited" })
}

# 2️⃣ Ensure EC2 Instances don't have Public IPs
resource "aws_config_config_rule" "ec2_no_public_ip" {
  name = "ec2-instance-no-public-ip"

  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
  }

  depends_on = [aws_config_configuration_recorder_status.tanvora_config_status]

  tags = merge(var.common_tags, { Name = "EC2 No Public IP" })
}

# 3️⃣ Ensure EBS volumes are encrypted
resource "aws_config_config_rule" "ebs_encrypted" {
  name = "encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder_status.tanvora_config_status]

  tags = merge(var.common_tags, { Name = "EBS Encrypted Volumes" })
}

# 4️⃣ Ensure IAM root account has MFA enabled
resource "aws_config_config_rule" "root_mfa" {
  name = "root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.tanvora_config_status]

  tags = merge(var.common_tags, { Name = "Root MFA Enabled" })
}

# 4️⃣7️⃣ SNS Topic for Compliance Alerts
resource "aws_sns_topic" "config_alerts_topic" {
  name = "${var.project_name}-config-alerts"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-config-alerts"
  })
}

# 4️⃣8️⃣ SNS Email Subscription
resource "aws_sns_topic_subscription" "config_alerts_email" {
  topic_arn = aws_sns_topic.config_alerts_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email   # 👈 We'll define this in variables.tf
}

# 4️⃣9️⃣ EventBridge Rule for Config Noncompliance
resource "aws_cloudwatch_event_rule" "config_noncompliant_rule" {
  name        = "${var.project_name}-config-noncompliance"
  description = "Triggers when AWS Config marks a resource NON_COMPLIANT"
  event_pattern = jsonencode({
    "source"      : ["aws.config"],
    "detail-type" : ["Config Rules Compliance Change"],
    "detail" : {
      "newEvaluationResult" : {
        "complianceType" : ["NON_COMPLIANT"]
      }
    }
  })

  tags = var.common_tags
}

# 5️⃣0️⃣ EventBridge Target → SNS
resource "aws_cloudwatch_event_target" "config_to_sns" {
  rule      = aws_cloudwatch_event_rule.config_noncompliant_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.config_alerts_topic.arn
}

# 5️⃣1️⃣ IAM Role for EventBridge to Publish to SNS
resource "aws_iam_role" "eventbridge_sns_role" {
  name = "${var.project_name}-eventbridge-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "events.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "eventbridge_sns_policy" {
  name = "${var.project_name}-eventbridge-sns-policy"
  role = aws_iam_role.eventbridge_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.config_alerts_topic.arn
      }
    ]
  })
}

# 5️⃣2️⃣ Attach Role to EventBridge Target
resource "aws_cloudwatch_event_target" "config_to_sns_with_role" {
  rule      = aws_cloudwatch_event_rule.config_noncompliant_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.config_alerts_topic.arn
  role_arn  = aws_iam_role.eventbridge_sns_role.arn
}

# 5️⃣3️⃣ IAM Group for Administrators
resource "aws_iam_group" "admins" {
  name = "Administrators"
}

# Attach AWS managed AdministratorAccess policy
resource "aws_iam_group_policy_attachment" "admins_attach" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 5️⃣4️⃣ IAM Group for Developers (Limited Access)
resource "aws_iam_group" "developers" {
  name = "Developers"
}

# Attach Developer-specific managed policies
resource "aws_iam_group_policy_attachment" "developers_attach" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# 5️⃣5️⃣ IAM Group for Auditors (Read-only)
resource "aws_iam_group" "auditors" {
  name = "Auditors"
}

# Attach ReadOnlyAccess policy
resource "aws_iam_group_policy_attachment" "auditors_attach" {
  group      = aws_iam_group.auditors.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# 5️⃣6️⃣ IAM Users
resource "aws_iam_user" "ajay_admin" {
  name          = "ajay.vishwakarma"
  force_destroy = true  # allows deletion without manual cleanup
  tags          = var.common_tags
}

resource "aws_iam_user" "raunak_dev" {
  name          = "raunak.developer"
  force_destroy = true
  tags          = var.common_tags
}

resource "aws_iam_user" "audit_user" {
  name          = "audit.user"
  force_destroy = true
  tags          = var.common_tags
}

# 5️⃣7️⃣ Add users to their groups
resource "aws_iam_user_group_membership" "ajay_to_admins" {
  user   = aws_iam_user.ajay_admin.name
  groups = [aws_iam_group.admins.name]
}

resource "aws_iam_user_group_membership" "raunak_to_devs" {
  user   = aws_iam_user.raunak_dev.name
  groups = [aws_iam_group.developers.name]
}

resource "aws_iam_user_group_membership" "audit_to_auditors" {
  user   = aws_iam_user.audit_user.name
  groups = [aws_iam_group.auditors.name]
}
