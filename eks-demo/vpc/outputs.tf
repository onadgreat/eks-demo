output "private" {
  value = aws_subnet.private.*.id
}

output "public" {
  value = aws_subnet.public.*.id
}

output "node_role" {
  value = aws_iam_role.demo.name
}

output "demo_role" {
  value = aws_iam_role.nodes.name
}

