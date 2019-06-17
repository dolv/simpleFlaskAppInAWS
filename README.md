This project initially aimed to provide answers to the testing task outlined here: https://github.com/devsbb/grover-engineering-recruitment
but goes far beyond that task and includes the following functionality:

* it contains a simple Flask application written in Python3 language as required in the mentioned upper repo including:
  * python code for the application
  * templates with bootstrap usage
  * route and code to provide REST responses.
* It additionally contains automation code written in python and terrafrom to bring-up the needed infrastructure in AWS including:
  * Terraform code for VPC, ECS cluster
  * Python3 based deployer.py application for deployment purposes
  * bash scripts for related tasks.
  
The final goal to present the following approach for the application:
* with the help of deployer.py script we create S3 bucket fo terraform state and automatically adjust existing terraform provider info inmain.tf
* with the help of deployer.py script in the same run we create IAM user with permissions to ECS/ECR.
* using build_jenkins_master_image.sh bash script we build Jenkins image 
* using `jenkin.sh init` script we spin-up jenkins container and initialize jenkins:
  * create AWS credentials of the user for interaction with ECR
  * cofigure ECS-Cloud with jenkins slaves.
  * create pipeline for building the demo application docker image, running teste, pushing it to the ECR registry.
  * create pipelien for deployment of the test to fargate.

  
