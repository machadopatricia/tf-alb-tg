variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Linux"
}

variable "ami" {
  type    = string
  default = "ami-00c39f71452c08778"
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

variable "alb_name" {
  type    = string
  default = "MyALB"
}
