variable "vpc_cidr" {
  description = "CIDR da VPC"
  type = string
}

variable "subnet_cidr" {
  description = "CIDR da subnet pública"
  type = string
}

variable "availability_zone" {
  description = "Zona de disponibilidade"
  type = string
}

variable "subnet_cidr_2" {
  description = "CIDR da segunda Subnet pública"
  type = string
}

variable "availability_zone_2" {
  description = "Segunda AZ"
  type = string
}

variable "environment" {
  description = "Nome do ambiente (dev, prod)"
  type = string
  default = "dev"
}