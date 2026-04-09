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

# Launch Template — molde para o Auto Scaling Group
resource "aws_launch_template" "app" {
  name_prefix = "app-lt-"
  image_id = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ aws_security_group.ec2_sg.id ]
  }

  # User data -script que roda na incialização de instancia
  user_data = base64encode(<<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
  echo "<h1> Hello From $(hostname)</h1>" > /var/www/html/index.html
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