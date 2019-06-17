## Summary
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
  
The final goal is to present the following approach for the application:
* with the help of deployer.py script we create S3 bucket fo terraform state and automatically adjust existing terraform provider info inmain.tf
* with the help of deployer.py script in the same run we create IAM user with permissions to ECS/ECR.
* using build_jenkins_master_image.sh bash script we build Jenkins image 
* using `jenkin.sh init` script we spin-up jenkins container and initialize jenkins:
  * create AWS credentials of the user for interaction with ECR
  * cofigure ECS-Cloud with jenkins slaves.
  * create pipeline for building the demo application docker image, running teste, pushing it to the ECR registry.
  * create pipelien for deployment of the test to fargate.
* using `jenkins.sh start` we spin-up preconfigured jenkins container.

## Installation and preparation for demo steps:
* The demo is intended to be executed from the Linux VM in AWS. So, please create EC2 instance in AWS of the t2.micro VM running Amazon Linux distribution and log into the host OS via SSH.
* When you are in run the following commands 
```bash
wget https://raw.githubusercontent.com/dolv/simpleFlaskAppInAWS/master/prepare_admin_host.sh
chmod +x prepare_admin_host.sh
./prepare_admin_host.sh
cd simpleFlaskAppInAWS
``` 
 this will install needed tools for further steps.
* then we need to bring up the infrastructure in AWS needed for the application DEMO. And we will be using Terraform. To make terrafrom be able to create resources on behalf of us it need AWS credentials. Edit shared credentials file `~/.aws/credentials` and substitute AAAAA... and BBBBB... with correct values for `aws_access_key_id` and `aws_secret_access_key`.
* (in progress) run `deploy.sh` to create the infrastructure resources in AWS, spin-up jenkins in docker container on the localhost and trigger needed jobs one-by-one to bring the demo application up.


