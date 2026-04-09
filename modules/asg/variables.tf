variable "vpc_id" {
  description = "ID da VPC"
  type = string
}

variable "subnet_ids" {
  description = "Lista de Subnets públicas"
  type = list(string)
}

variable "launch_template_id" {
  description = "ID do Launch Template"
  type = string
}

variable "instance_type" {
    description = "Tipo da Instancia"  
    type = string
}

variable "environment" {
  description = "Nome do ambiente (dev, prod)"
  type        = string
  default     = "dev"
}