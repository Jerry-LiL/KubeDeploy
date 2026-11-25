output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  value      = try(aws_nat_gateway.this[0].id, "")
  depends_on = [aws_route.private_nat, aws_route_table_association.private]
}
