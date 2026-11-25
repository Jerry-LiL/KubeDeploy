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

variable "github_repository" {
  type        = string
  description = "owner/name allowed to assume the GitHub Actions roles."
}

variable "state_bucket_name" {
  type        = string
  description = "Bucket created by the bootstrap stack. Must match backend.hcl."
}

variable "lock_table_name" {
  type    = string
  default = "kubedeploy-tflock"
}

variable "ecr_force_delete" {
  type    = bool
  default = true
}

variable "create_oidc_provider" {
  type        = bool
  description = "Set false when this account already has the GitHub OIDC provider."
  default     = true
}
