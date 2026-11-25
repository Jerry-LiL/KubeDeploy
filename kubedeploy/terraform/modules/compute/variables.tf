variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_profile_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ami_id" {
  type        = string
  description = "Pin an AMI, or leave empty to use the latest Amazon Linux 2023."
  default     = ""
}

variable "app_image" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "nat_gateway_id" {
  type    = string
  default = ""
}

variable "enable_nat" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
