data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_oidc_provider ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
  tags = var.tags
}

locals {
  oidc_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.oidc_provider_arn
  lock_arn = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:*"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "${var.name}-gha-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
  tags               = var.tags
}

resource "aws_iam_role" "terraform" {
  name               = "${var.name}-gha-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
  tags               = var.tags
}

resource "aws_iam_role" "instance" {
  name               = "${var.name}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ecr_push" {
  # GetAuthorizationToken does not accept a repository ARN.
  statement {
    sid       = "AuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PushPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.ecr_repository_arn]
  }
}

data "aws_iam_policy_document" "ecr_pull" {
  statement {
    sid       = "AuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "Pull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "ecr-push"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_role_policy" "instance_ecr" {
  name   = "ecr-pull"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-ec2"
  role = aws_iam_role.instance.name
  tags = var.tags
}

data "aws_iam_policy_document" "terraform" {
  statement {
    sid = "StateBucket"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket_name}",
      "arn:aws:s3:::${var.state_bucket_name}/*",
    ]
  }

  statement {
    sid = "LockTable"
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
    ]
    resources = [local.lock_arn]
  }

  statement {
    sid = "Registry"
    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "ecr:PutLifecyclePolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
      "ecr:TagResource",
      "ecr:UntagResource",
    ]
    resources = [var.ecr_repository_arn]
  }

  # CreateVpc and several related actions do not accept a resource ARN.
  # Every resource this role creates is tagged Project = kubedeploy.
  statement {
    sid = "NetworkAndCompute"
    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:Describe*",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ManageProjectRoles"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateInstanceProfile",
      "iam:CreateOpenIDConnectProvider",
      "iam:CreateRole",
      "iam:DeleteInstanceProfile",
      "iam:DeleteOpenIDConnectProvider",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetInstanceProfile",
      "iam:GetOpenIDConnectProvider",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.name}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
    ]
  }
}

resource "aws_iam_role_policy" "terraform" {
  name   = "terraform"
  role   = aws_iam_role.terraform.id
  policy = data.aws_iam_policy_document.terraform.json
}
