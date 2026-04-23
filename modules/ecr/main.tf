resource "aws_ecr_repository" "app" {
  # Nome único por ambiente
  name                 = "${var.environment}-app"
  image_tag_mutability = "MUTABLE"

  # Escaneia a imagem em busca de vulnerabilidades automaticamente
  # Em produção isso é essencial — detecta bibliotecas com CVEs conhecidos
  image_scanning_configuration {
    scan_on_push = true
  }

  # Força deleção mesmo com imagens dentro — útil para ambientes de dev
  # Em prod você removeria isso para evitar deleção acidental
  force_delete = true

  tags = {
    Name        = "${var.environment}-app"
    Environment = var.environment
  }
}

# Política de ciclo de vida — evita acúmulo infinito de imagens
# Mantém apenas as 5 últimas versões, deleta as antigas automaticamente
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Manter apenas as 5 ultimas imagens"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}