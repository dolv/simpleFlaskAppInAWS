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

resource "aws_ecr_repository" "repo" {
  count = length(var.ecr_repo_names)
  name = element(var.ecr_repo_names, count.index)
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.AmazonECSTaskExecutionRolePolicy.json
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