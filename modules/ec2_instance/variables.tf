variable "instance_type" {
  default = "t2.micro"
}

variable "ami" {}

variable "tags" {
  type = map(string)
  default = {
    Name = "jumphost"
  }
}

variable "ssh_key_name" {}

variable "monitoring_enabled" {
  type = bool
  default = true
}

variable "associate_public_ip_address" {
  type = bool
  default = true
}

variable "user_data" {
  type = string
  default = <<-EOF
    #!/bin/bash
    yum install -y git, vim
    amazon-linux-extras install docker
    usermod -a -G docker ec2-user
    service docker start

    EOF
}