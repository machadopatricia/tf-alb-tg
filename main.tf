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

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  tags = {
    tier = "public"
  }
}

resource "aws_security_group" "web_access" {
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

resource "aws_lb" "my_alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_access.id]
  subnets            = [data.aws_subnets.public_subnets.ids[0],data.aws_subnets.public_subnets.ids[1]]
}

resource "aws_lb_target_group" "alb_tg" {
  name        = "alb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
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
  //metrics are not enabling - troubleshoot
  enabled_metrics = []
  metrics_granularity = "1Minute"

  vpc_zone_identifier = [
    data.aws_subnets.public_subnets.ids[0],
    data.aws_subnets.public_subnets.ids[1],
    data.aws_subnets.public_subnets.ids[2]
    ]

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