#!/bin/sh

DOCKER_REGISTRY=nadoni/devops-nestjs-app

# build image
docker build -t ${DOCKER_REGISTRY} .

# add tags
docker tag ${DOCKER_REGISTRY}:latest ${DOCKER_REGISTRY}:v1.0

# push to registry
docker push ${DOCKER_REGISTRY}