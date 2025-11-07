provider "aws" {
  region = var.aws_region
}


module "vpc" {
  source = "./modules/vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  azs                  = ["${var.aws_region}a", "${var.aws_region}b"]
  environment          = terraform.workspace
}

module "load_balancing" {
  source = "./modules/load_balancing"
  vpc_id               = module.vpc.vpc_id
  public_subnets       = module.vpc.public_subnet_ids
  private_subnets      = module.vpc.private_subnet_ids
  proxy_instance_ids   = module.compute.proxy_instance_ids
  backend_instance_ids = module.compute.backend_instance_ids
  internal_alb_sg_id   = module.compute.internal_alb_sg_id 
  public_alb_sg_id     = module.compute.public_alb_sg_id
  public_subnets_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
}

module "compute" {
  source = "./modules/compute"
  vpc_id            = module.vpc.vpc_id
  public_subnets    = module.vpc.public_subnet_ids
  private_subnets   = module.vpc.private_subnet_ids
  key_pair_name     = var.key_pair_name
  private_key_path  = var.private_key_path
  ingress_cidrs     = var.ingress_cidrs
  internal_alb_dns = module.load_balancing.internal_alb_dns_name
  internal_alb_sg_id = module.load_balancing.internal_alb_sg_id 
  public_alb_sg_id   = module.load_balancing.public_alb_sg_id
}

output "public_alb_dns" {
  value = module.load_balancing.public_alb_dns_name
}