#!/bin/bash
set -e

docker build -t lab-app .
docker run -dit --name lab-app -p 8080:8080 lab-app

docker ps