#!/bin/bash
set -e

docker build -t lab-app-python .
docker run -dit --name lab-app-python -p 8080:8080 lab-app-python

docker ps