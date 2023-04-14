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

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  tags = {
    tier = "public"
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

resource "aws_security_group" "web_access" {
  name        = "WebAccess"
  description = "Allow HTTP to web server"
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

resource "aws_launch_template" "template_basic" {
  name                   = var.launch_template_name
  image_id               = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_access.id]
  user_data              = base64encode(var.user_data)

  block_device_mappings {
    device_name = var.block_device_name

    ebs {
      volume_size           = var.ebs_volume_size
      delete_on_termination = true
      volume_type           = var.ebs_volume_type
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      origin = "terraform"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = var.asg_name
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_grace_period = var.health_check_grace_period
  target_group_arns         = [aws_lb_target_group.tg_alb.arn]
  vpc_zone_identifier       = [for subnet in data.aws_subnet.public : subnet.id]

  launch_template {
    id      = aws_launch_template.template_basic.id
    version = "$Latest"
  }

  timeouts {
    delete = var.timeouts_delete
  }

  tag {
    key                 = "origin"
    value               = "terraform"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "tg_alb" {
  name        = var.tg_name
  port        = var.tg_alb_port
  protocol    = var.tg_alb_protocol
  target_type = var.tg_alb_target_type
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = var.alb_internal
  load_balancer_type = var.alb_type
  security_groups    = [aws_security_group.web_access.id]
  subnets            = [for subnet in data.aws_subnet.public : subnet.id]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_listener_port
  protocol          = var.alb_listener_protocol

  default_action {
    type             = var.alb_listener_default_action
    target_group_arn = aws_lb_target_group.tg_alb.arn
  }
}