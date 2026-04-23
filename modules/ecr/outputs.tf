output "repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "URL do repositório ECR"
}