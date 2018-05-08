# Docker4MLTutorial
A hands on tutorial on Docker and AWS Lambda for Machine Learning applications.

Videos and slides: http://hi.cs.stonybrook.edu/teaching/docker4ml

## Using the scripts
General sequence:
1. Use `Dockerfile.ultimate_ml` to build a container with your favorite ML framework.
2. Build a model you'd like to serve in the cloud. You can follow the script in `Serverless-ML-API-example.ipynb` to build an MNIST classifier with `sklearn` and `XGBoost`. Pickle the model to a file.
3. Modify `Dockerfile.aws_ami_for_lambda` to reflect a python execution environment for AWS Lambda that can run your model (e.g. if you used XGBoost you'd want XGBoost installed)
4. Use `docker_build_lambda_env.sh` to build the AWS Linux container and extract the packaged virtual environment files (`venv*.zip`)
5. Modify `lambda_function.py` to perform the prediction on your model depending on the inputs and outputs you expect (e.g. input MNIST digit pixels in a JSON array and output the predicted digit)
6. Create a Lambda function on AWS, give it a unique name.
7. Create an S3 bucket on AWS, give it a unique name.
8. Modify `lambda_config.py` with the names of the function, S3 bucket, region, etc.
9. Use `add_lambda_and_upload.sh` to upload the Lambda code, environment and ML model to S3 and then deploy everything to your lambda function.
10. Optionally create an AWS API Gateway to trigger the Lambda function on an HTTP request.

