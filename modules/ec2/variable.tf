variable "vpc_id" {
  description = "ID da vpc"
  type = string
}

variable "subnet_id" {
  description = "ID da subnet pública"
  type = string
}

variable "instance_type" {
  description = "Tipo da instancia EC2"
  type = string
  default = "t3.micro"
}

variable "ami_id" {
  description = "ID da AMI (Amazon Linux 2023)"
  type = string
}

variable "environment" {
  description = "Nome do ambiente (dev, prod)"
  type        = string
  default     = "dev"
}

variable "ecr_repository_url" {
  description = "URL do repositório ECR"
  type        = string
}