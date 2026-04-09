variable "aws_region" {
  description = "Regiãoi da AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR da vpc"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
}

variable "availability_zone" {
  description = "AZ da subnet"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "ID da AMI"
  type        = string
}

variable "subnet_cidr_2" {
  description = "CIDR da segunda subnet pública"
  type        = string
}

variable "availability_zone_2" {
  description = "Segunda AZ"
  type        = string
}