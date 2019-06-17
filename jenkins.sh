#!/usr/bin/env bash
set -e

MAX_TRIES=12
ONE_TRY_SLEEP=10

jenkins_container_name=jenkins
image=jenkins-master
tag='0.1.0'
jenkins_image=$image:$tag

homedir=~
eval homedir=$homedir
jenkins_home_dir_volume=$homedir/jenkins-test
mkdir -p $jenkins_home_dir_volume/init.groovy.d

function jenkinsIsReady() {
  (docker logs $jenkins_container_name 2>&1) | grep -qE "Jenkins is fully up and running"
}

function waitUntilServiceIsReady() {
  attempt=1
  while [ $attempt -le $MAX_TRIES ]; do
    if "$@"; then
      echo "$2 container is up!"
      break
    fi
    echo "Waiting for $2 container... (attempt: $((attempt++)))"
    sleep 5
  done

  if [ $attempt -gt $MAX_TRIES ]; then
    echo "Error: $2 not responding, cancelling set up"
    exit 1
  fi
}

function start(){
    docker run -d --name $jenkins_container_name \
    -p 8080:8080 -p 50000:50000 \
    -v $jenkins_home_dir_volume:/var/jenkins_home \
    $jenkins_image
#    waitUntilServiceIsReady jenkinsIsReady $jenkins_container_name
}

function stop(){
    docker stop $jenkins_container_name
    docker rm $jenkins_container_name
}

function init () {
  cp ./init.groovy.d/*.groovy $jenkins_home_dir_volume/init.groovy.d/
  cp *_credentials.ini $jenkins_home_dir_volume/init.groovy.d/
  start
  waitUntilServiceIsReady jenkinsIsReady $jenkins_container_name
  docker stop $jenkins_container_name
  docker rm $jenkins_container_name
  rm -rf $jenkins_home_dir_volume/init.groovy.d/*
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  init)
    init
    ;;
  retart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|init|restart}"
esac