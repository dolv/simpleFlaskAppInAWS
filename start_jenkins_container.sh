#!/usr/bin/env bash

homedir=~
eval homedir=$homedir
mkdir -p $homedir/jenkins
docker run -d --name jenkins -p 8080:8080 -p 50000:50000 -v $homedir/jenkins:/var/jenkins_home jenkins-master