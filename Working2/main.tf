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

# --- Call Modules ---

module "vpc" {
  source = "./modules/vpc"
  project_name = var.project_name
  aws_region   = var.aws_region
  common_tags  = var.common_tags
}

module "iam" {
  source = "./modules/iam"
  project_name = var.project_name
  common_tags  = var.common_tags
}

module "ec2" {
  source = "./modules/ec2"
  project_name = var.project_name
  common_tags  = var.common_tags
  vpc_id       = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_id
}

module "backup" {
  source = "./modules/backup"
  project_name = var.project_name
  common_tags  = var.common_tags
  ec2_arn      = module.ec2.ec2_arn
}

module "monitoring" {
  source = "./modules/monitoring"
  project_name = var.project_name
  common_tags  = var.common_tags
}
