terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

# LocalStack accepts any static credentials. These are not a real account.
provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    dynamodb = "http://localhost:4566"
    ec2      = "http://localhost:4566"
    ecr      = "http://localhost:4566"
    iam      = "http://localhost:4566"
    s3       = "http://localhost:4566"
    sts      = "http://localhost:4566"
  }
}

module "stack" {
  source               = "../../stack"
  project              = "kubedeploy"
  environment          = "local"
  aws_region           = var.aws_region
  github_repository    = var.github_repository
  state_bucket_name    = var.state_bucket_name
  lock_table_name      = var.lock_table_name
  enable_nat           = false
  ami_id               = "ami-0123456789abcdef0"
  ecr_force_delete     = true
  create_oidc_provider = false
  oidc_provider_arn    = "arn:aws:iam::000000000000:oidc-provider/token.actions.githubusercontent.com"
}
