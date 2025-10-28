
module "acm" {
  source          = "./modules/acm"
  aws_region      = var.aws_region
  project_name    = var.project_name
  domain_name     = var.domain_name
  route53_zone_id = module.route53.route53_zone_id
  common_tags     = var.common_tags
}


module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  aws_region           = var.aws_region
  common_tags          = var.common_tags
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  common_tags  = var.common_tags
}

module "ec2" {
  source             = "./modules/ec2"
  project_name       = var.project_name
  common_tags        = var.common_tags
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  ec2_role_name      = module.iam.ec2_role_name
}

module "backup" {
  source       = "./modules/backup"
  project_name = var.project_name
  common_tags  = var.common_tags
  ec2_id       = module.ec2.private_ec2_id
}

module "scaling" {
  source = "./modules/scaling"

  project_name       = var.project_name
  common_tags        = var.common_tags
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # Compute
  instance_type = "t3.micro"
  # ami_id                  = ""           # leave empty to auto-pick Amazon Linux 2
  iam_instance_profile_name = "${var.project_name}-ec2-profile" # from your IAM module

  # Capacity
  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  # App
  health_check_path = "/"
  # user_data               = file("${path.module}/bootstrap.sh")  # optional
  alb_certificate_arn = module.acm.alb_cert_arn # 👈 NEW
}

module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  common_tags        = var.common_tags
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  app_sg_id          = module.scaling.app_sg_id

  db_name     = "tanvoraapp"
  db_username = "admin"
  db_password = "Tanvora123!"
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  common_tags  = var.common_tags

  table_name    = "tanvora-users"
  hash_key      = "userId"
  hash_key_type = "S"
  sort_key      = "createdAt"
  sort_key_type = "S"
}

module "elasticache" {
  source             = "./modules/elasticache"
  project_name       = var.project_name
  common_tags        = var.common_tags
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  # private_cidr_blocks = [var.private_subnet_cidr_a, var.private_subnet_cidr_b]
  private_cidr_blocks = var.private_subnet_cidrs
}

module "monitoring" {
  source       = "./modules/monitoring"
  project_name = var.project_name
  aws_region   = var.aws_region
  common_tags  = var.common_tags
  alert_email  = var.alert_email
}

module "cloudfront" {
  source       = "./modules/cloudfront"
  project_name = var.project_name
  aws_region   = var.aws_region
  common_tags  = var.common_tags

  # optional: set if you want a specific name
  # bucket_name = "tanvora-cdn-static"

  # custom domain (optional)
  # domain_name     = "cdn.tanvora.com"
  # alternate_names = ["static.tanvora.com"]

  # If you want the module to also create the ACM DNS validation records:
  # route53_zone_id = "Z123456ABCDEFG"
}

module "route53" {
  source       = "./modules/route53"
  project_name = var.project_name
  domain_name  = "spakcommgroup.com"
  common_tags  = var.common_tags

  alb_dns_name = module.scaling.alb_dns_name
  alb_zone_id  = module.scaling.alb_zone_id

  cloudfront_domain_name    = module.cloudfront.cloudfront_domain_name
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2" # always same for CloudFront globally

  # Optional: if you also have api subdomain
  create_api_record = true
  api_dns_name      = module.scaling.alb_dns_name
  api_zone_id       = module.scaling.alb_zone_id
}






# YourStrongRedisPassword123