variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_repository" {
  type    = string
  default = "Jerry-LiL/KubeDeploy"
}

variable "state_bucket_name" {
  type    = string
  default = "kubedeploy-tfstate-local"
}

variable "lock_table_name" {
  type    = string
  default = "kubedeploy-tflock"
}
