output "proxy_instance_ids" {
  value       = aws_instance.proxy[*].id
}

output "backend_instance_ids" {
  value       = aws_instance.backend[*].id
}

output "internal_alb_sg_id" {
  value       = aws_security_group.backend_sg.id
}

output "public_alb_sg_id" {
  value       = aws_security_group.proxy_sg.id
}