variable "name" {
  type        = string
  description = "Repository name, for example kubedeploy/orders-api."
}

variable "force_delete" {
  type        = bool
  description = "Allow terraform destroy to delete a repository that still has images."
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
