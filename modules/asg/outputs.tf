output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "DNS público do Load Balancer"
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}