terraform {
    required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
   required_version = ">= 1.2.0"
    
   cloud {
       organization = "group07"
       
       workspaces {
           name = "infc_terraform"
       }
   }
}

provider "aws" {
    region  = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "Main"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.route.id
}

resource "aws_network_interface" "network_interface" {
  subnet_id       = aws_subnet.main.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.allow_tcp.id]

  attachment {
    instance     = aws_instance.linux.id
    device_index = 1
  }
}

resource "aws_security_group" "allow_tcp" {
    name        = "allow_tcp"
    description = "Allow TCP inbound traffic"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        description = "Allow incoming TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "linux" {
    ami = data.aws_ami.ubuntu-linux-2004.id
    instance_type = "t2.micro"
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.allow_tcp.id]
    subnet_id = aws_subnet.main.id

    user_data = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<h1>Hello World</h1>" | sudo tee /var/www/html/index.html
EOF
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.linux.public_dns
}
