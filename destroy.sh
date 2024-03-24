#!/bin/bash
set -e

docker stop lab-app-python
docker rm lab-app-python
docker rmi lab-app-python
