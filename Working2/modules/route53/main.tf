##############################################
# MODULE: Route 53 – Domain & DNS Records
##############################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

##############################################
# 1️⃣ Hosted Zone for Domain
##############################################

resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = merge(var.common_tags, { Name = "${var.project_name}-hosted-zone" })
}

##############################################
# 2️⃣ Root Domain → ALB
##############################################

resource "aws_route53_record" "root_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

##############################################
# 3️⃣ CDN Subdomain → CloudFront
##############################################

resource "aws_route53_record" "cdn_alias" {
  count   = var.create_cdn_record ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "cdn.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

##############################################
# 4️⃣ Optional API Subdomain → ALB or App Runner
##############################################

resource "aws_route53_record" "api_alias" {
  count   = var.create_api_record ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.api_dns_name
    zone_id                = var.api_zone_id
    evaluate_target_health = true
  }
}

# --------------------------------------------------
# Route53 Alias record for ALB
# --------------------------------------------------

# Lookup the hosted zone
data "aws_route53_zone" "primary" {
  name         = "spakcommgroup.com."
  private_zone = false
}

# Create an Alias record for the ALB
resource "aws_route53_record" "app_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "app.spakcommgroup.com"  # Subdomain for your app
  type    = "A"

  alias {
    # name                   = module.scaling.alb_dns_name   # from scaling module
    # zone_id                = module.scaling.alb_zone_id    # from scaling module
    name  = var.alb_dns_name
    zone_id = var.alb_zone_id
    evaluate_target_health = true
  }

  # ttl  = 300
}
