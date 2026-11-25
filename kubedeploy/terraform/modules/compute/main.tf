data "aws_ami" "amazon_linux" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux[0].id
}

resource "aws_instance" "app" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = false
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    image  = var.app_image
    region = var.aws_region
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  tags = merge(var.tags, { Name = "${var.name}-orders" })

  lifecycle {
    precondition {
      condition     = var.enable_nat == false || var.nat_gateway_id != ""
      error_message = "A NAT gateway is required when private instances need outbound access."
    }
  }
}
