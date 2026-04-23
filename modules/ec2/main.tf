# Security Group — controla tráfego de entrada e saída
resource "aws_security_group" "ec2_sg" {
    name = "${var.environment}-ec2-sg"
    description = "Security grup para EC2" 
    vpc_id = var.vpc_id

    ingress  {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress  {
        from_port = 0
        to_port = 0 
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
    Name        = "${var.environment}-ec2-sg"
    Environment = var.environment
    }
  
}

# Role IAM para a instância EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  # Permite que instâncias EC2 assumam essa role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Anexa a política gerenciada da AWS que permite acesso ao ECR
resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance Profile — é o que conecta a Role à instância EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Launch Template — molde para o Auto Scaling Group
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ aws_security_group.ec2_sg.id ]
  }

user_data = base64encode(<<-EOF
  #!/bin/bash
  # Atualiza o sistema
  yum update -y

  # Instala e inicia o Docker
  yum install -y docker
  systemctl start docker
  systemctl enable docker

  # Autentica no ECR
  # aws ecr get-login-password gera token temporário
  # o token é passado direto para o docker login
  aws ecr get-login-password --region us-east-1 | docker login \
    --username AWS \
    --password-stdin ${var.ecr_repository_url}

  # Baixa a imagem do ECR e roda o container
  # --restart always → reinicia o container se a instância reiniciar
  # -p 80:3000 → porta 80 da instância → porta 3000 do container
  docker run -d \
    --name app \
    --restart always \
    -p 80:3000 \
    ${var.ecr_repository_url}:latest
EOF
)
  tag_specifications {
    resource_type = "instance"
    tags = {
        Name = "app-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}