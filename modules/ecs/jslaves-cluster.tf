resource "aws_ecs_cluster" "jslaves" {
  name = "jslaves"
}

data "aws_ami" "jslave" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-03a71cec707bfc3d7"]
  }

  owners = ["137112412989"] # amazon
}

resource "aws_launch_configuration" "lc-jslave" {
  name_prefix   = "terraform-lc-jslave"
  image_id      = data.aws_ami.jslave.id
  instance_type = "t2.micro"
  key_name = var.admin_ssh_key_pair_name
  iam_instance_profile ="grover-test-account"
  user_data = <<-EOF
    #!/bin/bash
    yum install -y ecs-init
    service docker start

    mkdir -p /etc/ecs && touch /etc/ecs/ecs.config
    echo ECS_CLUSTER=${aws_ecs_cluster.jslaves.name} >> /etc/ecs/ecs.config
    start ecs

    EOF
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "jslave" {
  name                 = "terraform-asg-jslave"
  launch_configuration = aws_launch_configuration.lc-jslave.name
  min_size             = 1
  max_size             = 2
  availability_zones   = var.jslave_asg_availability_zones
  vpc_zone_identifier  = var.jslave_vpc_zone_identifiers

  lifecycle {
    create_before_destroy = true
  }
}