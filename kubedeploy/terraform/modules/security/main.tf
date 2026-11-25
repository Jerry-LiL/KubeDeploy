resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "orders-api listeners in the private subnets"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-app" })
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.app.id
  description       = "orders-api from inside the VPC"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS for ECR and SSM"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "dns" {
  security_group_id = aws_security_group.app.id
  description       = "DNS inside the VPC"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = var.vpc_cidr
}
