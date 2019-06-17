variable "ecr_repo_names" {
  type = list(string)
  default = ["jenkins-master", "jenkins-slave", "test-task-app"]
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 5000
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = 512
}

variable "app_image" {
  type = string
  description = "Docker image to run in the ECS cluster"
  default     = "126981522510.dkr.ecr.eu-central-1.amazonaws.com/test-task-app:latest"
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 2
}

variable "alb_target_group_app_id" {
  description = "Id of the targer group in ALB for app"
}

variable "jslave_vpc_zone_identifiers" {
  type = list(string)
}

variable "jslave_asg_availability_zones" {
  type = list(string)
}

variable "admin_ssh_key_pair_name" {}

variable "app_service_subnets" {
  type = list(string)
}

variable "app_service_ecs_tasks_security_group_ids" {
  type = list(string)
}
