#!/usr/bin/env bash

tee .dockerignore <<-'EOF'
*
!init.groovy.d/**
!jenkins_plugins.txt
EOF

docker build -t jenkins-master:latest -f Dockerfile_jenkins_master .