variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR da subnet pública 1"
  type        = string
}

variable "availability_zone" {
  description = "AZ da subnet 1"
  type        = string
}

variable "subnet_cidr_2" {
  description = "CIDR da subnet pública 2"
  type        = string
}

variable "availability_zone_2" {
  description = "AZ da subnet 2"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
}

variable "ami_id" {
  description = "ID da AMI"
  type        = string
}