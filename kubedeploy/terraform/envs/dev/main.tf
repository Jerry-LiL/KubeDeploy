terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "stack" {
  source               = "../../stack"
  project              = var.project
  environment          = var.environment
  aws_region           = var.aws_region
  github_repository    = var.github_repository
  state_bucket_name    = var.state_bucket_name
  lock_table_name      = var.lock_table_name
  enable_nat           = true
  ecr_force_delete     = var.ecr_force_delete
  create_oidc_provider = var.create_oidc_provider
}
