##############################################
# MODULE: ACM Certificates (ALB + CloudFront)
##############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ---------- Providers ----------
provider "aws" {
  region = var.aws_region           # e.g. ap-south-1
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"              # Required for CloudFront
}

# ---------- ALB Certificate ----------
resource "aws_acm_certificate" "alb_cert" {
  domain_name               = var.domain_name
  subject_alternative_names = [
    "app.${var.domain_name}",
    "api.${var.domain_name}"
  ]
  validation_method = "DNS"
  tags              = merge(var.common_tags, { Name = "${var.project_name}-alb-cert" })
}

# DNS validation records for ALB
resource "aws_route53_record" "alb_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = var.route53_zone_id
  records = [each.value.record]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "alb_valid" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.alb_validation : r.fqdn]
}

# ---------- CloudFront Certificate ----------
resource "aws_acm_certificate" "cf_cert" {
  provider          = aws.use1
  domain_name       = "cdn.${var.domain_name}"
  validation_method = "DNS"
  tags              = merge(var.common_tags, { Name = "${var.project_name}-cloudfront-cert" })
}

resource "aws_route53_record" "cf_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cf_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  provider = aws.use1
  name     = each.value.name
  type     = each.value.type
  zone_id  = var.route53_zone_id
  records  = [each.value.record]
  ttl      = 300
}

resource "aws_acm_certificate_validation" "cf_valid" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.cf_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cf_validation : r.fqdn]
}
