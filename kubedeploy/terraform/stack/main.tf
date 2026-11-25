locals {
  name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source               = "../modules/vpc"
  name                 = local.name
  cidr                 = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat           = var.enable_nat
  tags                 = local.tags
}

module "security" {
  source   = "../modules/security"
  name     = local.name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

module "ecr" {
  source       = "../modules/ecr"
  name         = "${var.project}/orders-api"
  force_delete = var.ecr_force_delete
  tags         = local.tags
}

module "iam" {
  source               = "../modules/iam"
  name                 = local.name
  github_repository    = var.github_repository
  create_oidc_provider = var.create_oidc_provider
  oidc_provider_arn    = var.oidc_provider_arn
  ecr_repository_arn   = module.ecr.repository_arn
  state_bucket_name    = var.state_bucket_name
  lock_table_name      = var.lock_table_name
  aws_region           = var.aws_region
  tags                 = local.tags
}

module "compute" {
  source                = "../modules/compute"
  name                  = local.name
  subnet_id             = module.vpc.private_subnet_ids[0]
  security_group_ids    = [module.security.app_security_group_id]
  instance_profile_name = module.iam.instance_profile_name
  instance_type         = var.instance_type
  ami_id                = var.ami_id
  app_image             = "${module.ecr.repository_url}:latest"
  aws_region            = var.aws_region
  nat_gateway_id        = module.vpc.nat_gateway_id
  enable_nat            = var.enable_nat
  tags                  = local.tags
}
