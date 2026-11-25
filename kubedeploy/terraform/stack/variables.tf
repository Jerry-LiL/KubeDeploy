variable "project" {
  type    = string
  default = "kubedeploy"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.40.0.0/24", "10.40.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.40.10.0/24", "10.40.11.0/24"]
}

variable "enable_nat" {
  type    = bool
  default = true
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ami_id" {
  type    = string
  default = ""
}

variable "github_repository" {
  type = string
}

variable "create_oidc_provider" {
  type    = bool
  default = true
}

variable "oidc_provider_arn" {
  type    = string
  default = ""
}

variable "ecr_force_delete" {
  type    = bool
  default = false
}

variable "state_bucket_name" {
  type = string
}

variable "lock_table_name" {
  type    = string
  default = "kubedeploy-tflock"
}
