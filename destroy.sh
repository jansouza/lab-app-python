#!/bin/bash
set -e

docker stop lab-app
docker rm lab-app
docker rmi lab-app
