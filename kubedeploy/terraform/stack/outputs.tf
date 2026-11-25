output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "app_security_group_id" {
  value = module.security.app_security_group_id
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "deploy_role_arn" {
  value = module.iam.deploy_role_arn
}

output "terraform_role_arn" {
  value = module.iam.terraform_role_arn
}

output "instance_id" {
  value = module.compute.instance_id
}
