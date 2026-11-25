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

variable "state_bucket_name" {
  type        = string
  description = "Globally unique name for the Terraform state bucket."
}

variable "lock_table_name" {
  type    = string
  default = "kubedeploy-tflock"
}
