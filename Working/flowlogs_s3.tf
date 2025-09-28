resource "aws_s3_bucket" "flow_logs" {
  bucket = "${var.project}-${var.environment}-flowlogs-${var.aws_region}"

  tags = {
    Name = "${var.project}-${var.environment}-flowlogs"
  }
}

# Block public access (industry standard)
resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_flow_log" "s3" {
  vpc_id               = aws_vpc.this.id
  log_destination      = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"

  tags = {
    Name = "${var.project}-${var.environment}-vpc-flowlogs-s3"
  }
}
