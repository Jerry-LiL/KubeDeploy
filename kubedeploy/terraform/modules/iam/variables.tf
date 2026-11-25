variable "name" {
  type = string
}

variable "github_repository" {
  type        = string
  description = "GitHub repository allowed to assume the deploy roles, as owner/name."
}

variable "create_oidc_provider" {
  type        = bool
  description = "Create the GitHub OIDC provider. An account can only have one."
  default     = true
}

variable "oidc_provider_arn" {
  type        = string
  description = "Existing GitHub OIDC provider ARN, used when create_oidc_provider is false."
  default     = ""
}

variable "ecr_repository_arn" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "lock_table_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
