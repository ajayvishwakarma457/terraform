#############################
# CloudFront + S3 + (ACM)
#############################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider = your workload region (for S3)
provider "aws" {
  region = var.aws_region
}

# CloudFront requires ACM cert in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

#############################
# S3 Bucket for Static Assets
#############################

resource "aws_s3_bucket" "cdn_bucket" {
  bucket = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-cdn-${var.aws_region}"
  tags   = merge(var.common_tags, { Name = "${var.project_name}-cdn" })
}

resource "aws_s3_bucket_versioning" "cdn_versioning" {
  bucket = aws_s3_bucket.cdn_bucket.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cdn_sse" {
  bucket = aws_s3_bucket.cdn_bucket.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "cdn_pab" {
  bucket                  = aws_s3_bucket.cdn_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# (Optional) Simple index.html so you can test immediately
resource "aws_s3_object" "index_html" {
  count        = var.create_test_index ? 1 : 0
  bucket       = aws_s3_bucket.cdn_bucket.id
  key          = "index.html"
  content      = "<!doctype html><html><head><meta charset='utf-8'><title>${var.project_name} CDN</title></head><body><h1>${var.project_name} CDN OK</h1></body></html>"
  content_type = "text/html"
}

#############################
# ACM (Optional) – us-east-1
#############################

# Only create cert if a domain is provided
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = var.alternate_names
  tags = merge(var.common_tags, { Name = "${var.project_name}-cdn-cert" })
}

# Create DNS validation records if a hosted zone is provided
resource "aws_route53_record" "cert_validation" {
  count   = var.domain_name != "" && var.route53_zone_id != "" ? length(aws_acm_certificate.cert[0].domain_validation_options) : 0
  zone_id = var.route53_zone_id
  name    = aws_acm_certificate.cert[0].domain_validation_options[count.index].resource_record_name
  type    = aws_acm_certificate.cert[0].domain_validation_options[count.index].resource_record_type
  records = [aws_acm_certificate.cert[0].domain_validation_options[count.index].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  count                   = var.domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = var.route53_zone_id != "" ? [for r in aws_route53_record.cert_validation : r.fqdn] : []
  depends_on              = [aws_route53_record.cert_validation]
}

#############################
# CloudFront (with OAC)
#############################

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  use_custom_cert = var.domain_name != "" && (length(aws_acm_certificate_validation.cert_validation) > 0 || var.route53_zone_id == "")
  aliases         = var.domain_name != "" ? concat([var.domain_name], var.alternate_names) : []
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  price_class         = var.price_class
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = local.aliases

  origin {
    domain_name = aws_s3_bucket.cdn_bucket.bucket_regional_domain_name
    origin_id   = "s3-origin-${aws_s3_bucket.cdn_bucket.id}"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin-${aws_s3_bucket.cdn_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    compress = true

    # Use AWS managed cache/req policies or make variables if you want custom
    cache_policy_id            = var.cache_policy_id != "" ? var.cache_policy_id : "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    origin_request_policy_id   = var.origin_request_policy_id != "" ? var.origin_request_policy_id : "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # Managed-CORS-S3Origin
    response_headers_policy_id = var.response_headers_policy_id != "" ? var.response_headers_policy_id : null
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Viewer cert
  viewer_certificate {
    acm_certificate_arn            = local.use_custom_cert ? aws_acm_certificate.cert[0].arn : null
    ssl_support_method             = local.use_custom_cert ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = local.use_custom_cert ? false : true
  }

  tags = merge(var.common_tags, { Name = "${var.project_name}-cdn" })

  depends_on = [
    aws_cloudfront_origin_access_control.oac,
    aws_s3_bucket_public_access_block.cdn_pab,
    aws_s3_bucket_server_side_encryption_configuration.cdn_sse
  ]
}

#############################
# S3 Bucket Policy (allow only CloudFront via OAC)
#############################

data "aws_caller_identity" "current" {}

# Allow CloudFront distribution to read from the bucket using OAC
resource "aws_s3_bucket_policy" "cdn_bucket_policy" {
  bucket = aws_s3_bucket.cdn_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowCloudFrontServicePrincipalRead",
        Effect: "Allow",
        Principal: { Service: "cloudfront.amazonaws.com" },
        Action: ["s3:GetObject"],
        Resource: "${aws_s3_bucket.cdn_bucket.arn}/*",
        Condition: {
          StringEquals: {
            "AWS:SourceArn": aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}


