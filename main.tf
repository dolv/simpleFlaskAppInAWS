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

### Network

# Fetch AZs in the current region
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "172.17.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_default_security_group" "default"{
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_vpc.main]
}

# Create var.az_count private subnets, each in a different AZ
resource "aws_subnet" "private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id

  depends_on = [aws_vpc.main]
}

# Create var.az_count public subnets, each in a different AZ
resource "aws_subnet" "public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  depends_on = [aws_vpc.main]
}

# IGW for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  depends_on = [aws_vpc.main]
}

# Create a NAT gateway with an EIP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
  count      = var.az_count
  vpc        = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "gw" {
  count         = var.az_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gw.*.id, count.index)
}

# Create a new route table for the private subnets
# And make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gw.*.id, count.index)
  }

  depends_on = [aws_vpc.main]
}

# Explicitely associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)

  depends_on = [aws_subnet.private, aws_route_table.private]
}

### Security
# Add SSH access to default SG of the

# ALB Security group
# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "lb" {
  name        = "tf-ecs-alb-sb"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_vpc.main]
}

# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "tf-ecs-tasks"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [
      aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_vpc.main]
}

### ALB

resource "aws_lb" "main" {
  name               = "tf-ecs-front-lb"
  load_balancer_type = "application"
  subnets            = [
    for subnet in aws_subnet.public:
          subnet.id
    ]
  security_groups    = [
    aws_security_group.lb.id]

  depends_on = [aws_subnet.public, aws_security_group.lb]
}

resource "aws_alb_target_group" "app" {
  name        = "tf-ecs-front-lb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  depends_on = [aws_vpc.main]
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }

  depends_on = [aws_lb.main, aws_alb_target_group.app]
}

### ECS

data "aws_iam_policy_document" "AmazonECSTaskExecutionRolePolicy" {
  statement {
		effect = "Allow"
		actions = [
            "sts:AssumeRole"
		]
        principals {
          type        = "Service"
          identifiers = [
            "ecs-tasks.amazonaws.com"
          ]
        }
	}
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.AmazonECSTaskExecutionRolePolicy.json
}

resource "aws_ecs_cluster" "main" {
  name = "tf-ecs-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn


  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.fargate_cpu},
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/test-task-app:latest",
    "memory": ${var.fargate_memory},
    "name": "app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.app_port},
        "hostPort": ${var.app_port}
      }
    ]
  }
]
DEFINITION
  depends_on = [aws_iam_role.ecs_task_execution_role]
}

resource "aws_ecs_service" "main" {
  name            = "tf-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = [
      for subnet in aws_subnet.private:
            subnet.id
    ]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "app"
    container_port   = var.app_port
  }

  depends_on = [
    "aws_alb_listener.front_end",
  ]
}

resource "aws_ecs_cluster" "jslaves" {
  name = "jslaves"
}

resource "aws_ecr_repository" "repo" {
  count = length(var.ecr_repo_names)
  name = element(var.ecr_repo_names, count.index)
}

data "aws_ami" "jslave" {
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

resource "aws_launch_configuration" "lc-jslave" {
  name_prefix   = "terraform-lc-jslave"
  image_id      = data.aws_ami.jslave.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.admin_ssh_key.key_name
  iam_instance_profile = aws_iam_instance_profile.escInctanceProfile.name
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

  depends_on = [
    "aws_key_pair.admin_ssh_key",
  ]
}

resource "aws_autoscaling_group" "jslave" {
  name                 = "terraform-asg-jslave"
  launch_configuration = aws_launch_configuration.lc-jslave.name
  min_size             = 1
  max_size             = 2
  availability_zones   = data.aws_availability_zones.available.names
  vpc_zone_identifier  = [
    for subnet in aws_subnet.public:
          subnet.id
  ]

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ec2TrastRelationShip" {
  statement {
		effect = "Allow"
		actions = [
            "sts:AssumeRole"
		]
        principals {
          type        = "Service"
          identifiers = [
            "ec2.amazonaws.com"
          ]
        }
	}
}

resource "aws_iam_role" "ecsInstanceRole" {
  name = "ecsInstanceRole"
  assume_role_policy = data.aws_iam_policy_document.ec2TrastRelationShip.json
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerServiceforEC2Role" {
  role       = aws_iam_role.ecsInstanceRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "escInctanceProfile" {
  name = "escInctanceProfile"
  role = aws_iam_role.ecsInstanceRole.name
}


