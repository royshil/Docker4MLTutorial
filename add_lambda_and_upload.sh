#!/bin/bash
#
#   description: This script is used to build the AWS lambda function given the lambda_function.py script
#                and the venv.zip file with the environment, and upload to S3.
#   author: Roy Shilkrot
#   date: 11/13/2017
#
#   Assumes user has AWS CLI installed: https://aws.amazon.com/cli/
#   This assumes the user has `aid` profile configured for the AWS CLI, look in ~/.aws/credentials
#
#   Usage: ./add_lambda_and_upload.sh <venv.zip> <venv_extra.zip> <lambda_function.py> <lambda function name> <model file>
#    

set -ex

if [ "$#" -ne 5 ]; then
    echo "Usage: ./add_lambda_and_upload.sh <venv.zip> <venv_extra.zip> <lambda_function.py> <lambda function name> <model file>"
    exit
fi

BUCKET_NAME=lambda-deploy-ml
REGION_NAME=us-east-2
AWS_CLI_PROFILE=default

# prepare configuration file for the lambda function
cat << EOF > lambda_config.py
S3_BUCKET_NAME="${BUCKET_NAME}"
VENV_EXTRA_FILE="$2"
MODEL_FILE="$5"
REGION_NAME="${REGION_NAME}"
EOF

# update the lambda venv zip with the function code and config
NEW_FILE=lambda_venv_$(date +%s).zip
cp $1 $NEW_FILE
zip -ju $NEW_FILE $3 lambda_config.py

# --- upload to S3
# remove old versions:
aws --profile ${AWS_CLI_PROFILE} s3 rm s3://${BUCKET_NAME}/ --recursive --exclude "*" --include "lambda_venv*"
# lambda function:
aws --profile ${AWS_CLI_PROFILE} s3 cp $NEW_FILE s3://${BUCKET_NAME}/
# extra environment
aws --profile ${AWS_CLI_PROFILE} s3 sync . s3://${BUCKET_NAME}/ --exclude '*' --include "$2" --include "$5" # upload if not exists

# reload the lambda functions
aws --profile ${AWS_CLI_PROFILE} --region ${REGION_NAME} lambda update-function-code --function-name $4 --s3-bucket ${BUCKET_NAME} --s3-key "$NEW_FILE"

rm $NEW_FILE
