variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "eu-central-1"
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}

variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "126981522510.dkr.ecr.eu-central-1.amazonaws.com/test-task-app:latest"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 5000
}

variable "app_count" {
  description = "Number of docker containers to run"
  default     = 2
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "ecr_repo_names" {
  type = list(string)
  default = ["jenkins-master", "jenkins-slave", "test-task-app"]
}

variable "public_key_filename" {
  description = "Path to the SSH public key file ()"
  default = "/Users/dolv/.ssh/id_rsa.pub"
}
