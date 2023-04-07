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
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "subnet_1b" {
  availability_zone = "us-east-1b"
  vpc_id = data.aws_vpc.default.id
}

data "aws_subnet" "subnet_1c" {
  availability_zone = "us-east-1c"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "WebAccess" {
  name        = "WebAccess"
  description = "Allow HTTPS to web server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_instance" "linux" {
  ami             = var.ami
  instance_type   = var.instance_type
  security_groups = [var.security_groups]
  user_data       = var.user_data
  availability_zone = "us-east-1b"

  tags = {
    Name   = var.instance_name
    origin = "tf"
  }
}

resource "aws_lb" "MyALB" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnet.subnet_1b,data.aws_subnet.subnet_1c]

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "alb-tg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.MyALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}