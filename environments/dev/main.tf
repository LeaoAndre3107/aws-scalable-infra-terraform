terraform {
  backend "s3"{
    bucket = "terraform-state-devops-andre-2"
    key = "dev/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source              = "../../modules/vpc"
  environment = "dev"
  vpc_cidr            = var.vpc_cidr
  subnet_cidr         = var.subnet_cidr
  availability_zone   = var.availability_zone
  subnet_cidr_2       = var.subnet_cidr_2
  availability_zone_2 = var.availability_zone_2
}

module "ec2" {
  source             = "../../modules/ec2"
  environment        = "dev"
  vpc_id             = module.vpc.vpc_id
  subnet_id          = module.vpc.subnet_id
  instance_type      = var.instance_type
  ami_id             = var.ami_id
  ecr_repository_url = module.ecr.repository_url
}

module "asg" {
  source             = "../../modules/asg"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = [module.vpc.subnet_id, module.vpc.subnet_id_2]
  launch_template_id = module.ec2.launch_template_id
  instance_type      = var.instance_type
}

output "alb_dns_name" {
  value = module.asg.alb_dns_name
}

module "ecr" {
  source      = "../../modules/ecr"
  environment = "dev"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}