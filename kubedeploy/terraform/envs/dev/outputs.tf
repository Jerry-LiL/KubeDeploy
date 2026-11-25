output "vpc_id" {
  value = module.stack.vpc_id
}

output "private_subnet_ids" {
  value = module.stack.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.stack.public_subnet_ids
}

output "ecr_repository_url" {
  value = module.stack.ecr_repository_url
}

output "deploy_role_arn" {
  value = module.stack.deploy_role_arn
}

output "terraform_role_arn" {
  value = module.stack.terraform_role_arn
}

output "instance_id" {
  value = module.stack.instance_id
}
