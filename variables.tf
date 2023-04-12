variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Linux"
}

variable "alb_name" {
  type    = string
  default = "MyALB"
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
  description = "WebServer HelloWorld user data"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd.x86_64
    systemctl start httpd.service
    systemctl enable httpd.service
    echo “Hello World from $(hostname -f)” > /var/www/html/index.html
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