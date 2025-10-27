
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

# module "monitoring" {
#   source       = "./modules/monitoring"
#   project_name = var.project_name
#   aws_region   = var.aws_region
#   common_tags  = var.common_tags
#   alert_email  = var.alert_email
# }

