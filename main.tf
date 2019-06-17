terraform {
  backend "s3" {
    bucket = "terraform-wqibir"
    key    = "grover/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  version = "~> 2.0"
  region = "eu-central-1"
  shared_credentials_file = "/Users/dolv/.aws/credentials"
  profile ="grover-test-account"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "image-id"
    values = ["ami-03a71cec707bfc3d7"]
  }

  owners = ["137112412989"] # amazon
}


resource "aws_key_pair" "admin_ssh_key" {
  key_name   = "admin_ssh_key"
  public_key = file(var.public_key_filename)
}

module "admin_host" {
  source = "./modules/ec2_instance"
  ami = data.aws_ami.amazon_linux.id
  ssh_key_name = aws_key_pair.admin_ssh_key.key_name
}

module "networking" {
    source = "./modules/networking"
    app_port = 5000
    aws_region = data.aws_region.current
}

module "ecs" {
  source = "./modules/ecs"
  app_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/test-task-app:latest"
  app_service_subnets = module.networking.private_subnet_ids
  alb_target_group_app_id = module.networking.alb_target_group_app_id
  admin_ssh_key_pair_name = aws_key_pair.admin_ssh_key.key_name
  jslave_asg_availability_zones = module.networking.region_availability_zones_names
  jslave_vpc_zone_identifiers = module.networking.private_subnet_ids
  app_service_ecs_tasks_security_group_ids = module.networking.esc_tasks_security_group_ids
}
