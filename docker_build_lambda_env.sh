#!/bin/bash
#
#   description: This script is used to build the AWS lambda function's python environment with Docker, 
#                and copy the zipped environment out of the container (as well as delete it, but not the image).
#   author: Roy Shilkrot
#   date: 4/16/2018
#
#   Assumes user has Docker installed, and the file `Dockerfile.aws_ami_for_lambda` exists
#
#   Usage: ./docker_build_lambda_env.sh
#    

set -ex

OUTPUT_VENV=./venv_$(date +"%Y%m%d%H%M").zip
OUTPUT_VENV_EXTRA=./venv_extra_$(date +"%Y%m%d%H%M").zip
DOCKER_IMAGE=ami_lambda_env

docker build -f Dockerfile.aws_ami_for_lambda -t ${DOCKER_IMAGE} .
CONTAINER_ID=$(docker run -d ${DOCKER_IMAGE}:latest)
docker cp ${CONTAINER_ID}:/lambda_build/outputs/venv.zip ${OUTPUT_VENV}
docker cp ${CONTAINER_ID}:/lambda_build/outputs/venv_extra.zip ${OUTPUT_VENV_EXTRA}
docker rm ${CONTAINER_ID}

echo ${OUTPUT_VENV}
echo ${OUTPUT_VENV_EXTRA}