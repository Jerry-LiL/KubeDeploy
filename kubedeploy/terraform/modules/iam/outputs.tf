output "deploy_role_arn" {
  value = aws_iam_role.deploy.arn
}

output "terraform_role_arn" {
  value = aws_iam_role.terraform.arn
}

output "instance_role_arn" {
  value = aws_iam_role.instance.arn
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2.name
}
