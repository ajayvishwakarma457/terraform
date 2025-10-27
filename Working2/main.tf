
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
}


# module "monitoring" {
#   source       = "./modules/monitoring"
#   project_name = var.project_name
#   aws_region   = var.aws_region
#   common_tags  = var.common_tags
#   alert_email  = var.alert_email
# }

