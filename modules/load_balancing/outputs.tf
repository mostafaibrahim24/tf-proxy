output "public_alb_dns_name" {
  value       = aws_lb.public_alb.dns_name
}

output "internal_alb_dns_name" {
  value       = aws_lb.internal_alb.dns_name
}

output "public_alb_sg_id" {
  value       = aws_security_group.public_alb_sg.id
}

output "internal_alb_sg_id" {
  value       = aws_security_group.internal_alb_sg.id
}