output "launch_template_id" {
  value = aws_launch_template.app.id
}

output "security_groups_id" {
  value = aws_security_group.ec2_sg.id
}