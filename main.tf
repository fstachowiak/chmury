terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_instance" "ec2_tic_tac_toe" {
  ami                    = "ami-051f8a213df8bc089"
  instance_type          = "t2.micro"
  key_name               = "key"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = {
    Name = "Ec2 Tic-tac-toe tf"
  }

  user_data = "${file("install.sh")}"
}

resource "aws_vpc" "vpc_tf" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Vpc Tic-tac-toe tf"
  }
}

resource "aws_subnet" "subnet_tf" {
  vpc_id     = aws_vpc.vpc_tf.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Subnet Tic-tac-toe tf"
  }
}

resource "aws_internet_gateway" "igw_tf" {
  vpc_id = aws_vpc.vpc_tf.id

  tags = {
    Name = "Gateway Tic-tac-toe tf"
  }
}

resource "aws_route_table" "rt_tf" {
  vpc_id = aws_vpc.vpc_tf.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_tf.id
  }

  tags = {
    Name = "Route table Tic-tac-toe tf"
  }

}

resource "aws_route_table_association" "subnet_tf" {
  subnet_id      = aws_subnet.subnet_tf.id
  route_table_id = aws_route_table.rt_tf.id
}


resource "aws_security_group" "main" {
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    description = "Backend"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    description = "Frontend"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name = "key"
  public_key = "${file("key.pub")}"
}