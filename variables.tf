variable "region" {
  type    = string
  default = "us-east-1"
}

#### LAUNCH TEMPLATE VARIABLES ####

variable "launch_template_name" {
  type    = string
  default = "MyLaunchTemplate"
}

variable "ami" {
  type    = string
  default = "ami-0fa1de1d60de6a97e"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "user_data" {
  description = "WebServer to show availability zone"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    EC2AZ=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo '<center><h1>This Amazon EC2 instance is located in Availability Zone: AZID </h1></center>' > /var/www/html/index.txt
    sed "s/AZID/$EC2AZ/" /var/www/html/index.txt > /var/www/html/index.html
  EOF
}

variable "block_device_name" {
  type    = string
  default = "/dev/xvda"
}

variable "ebs_volume_size" {
  type    = number
  default = 8
}

variable "ebs_volume_type" {
  type    = string
  default = "gp2"
}

#### AUTO SCALING GROUP VARIABLES ####

variable "asg_name" {
  type    = string
  default = "MyASG"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "health_check_grace_period" {
  type    = number
  default = 300
}

variable "timeouts_delete" {
  type    = string
  default = "10m"
}

#### TARGET GROUP VARIABLES ####

variable "tg_name" {
  type    = string
  default = "TG-ALB"
}

variable "tg_alb_port" {
  type    = number
  default = 80
}

variable "tg_alb_protocol" {
  type    = string
  default = "HTTP"
}

variable "tg_alb_target_type" {
  type    = string
  default = "instance"
}

#### APPLICATION LOAD BALANCER VARIABLES ####

variable "alb_name" {
  type    = string
  default = "MyALB"
}

variable "alb_internal" {
  type    = bool
  default = false
}

variable "alb_type" {
  type    = string
  default = "application"
}

#### ALB LISTENER VARIABLES ####

variable "alb_listener_port" {
  type    = string
  default = "80"
}

variable "alb_listener_protocol" {
  type    = string
  default = "HTTP"
}

variable "alb_listener_default_action" {
  type    = string
  default = "forward"
}

