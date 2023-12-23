#!/bin/sh

DOCKER_REGISTRY=nadoni/devops-nestjs-app

docker run -d -p 81:3000 --name registry ${DOCKER_REGISTRY}:latest