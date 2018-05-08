import boto3
import botocore.config
import sys
import logging
import traceback
import random
import json
import pickle
import os
import ctypes
import uuid
import zipfile
import io
import imp
import math

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

from lambda_config import *

config = botocore.config.Config()
config.region_name = REGION_NAME
config.connection_timeout = 60
config.read_timeout = 60

s3_client = boto3.client('s3')

def download_peripherals(keys):
    global s3_client
    
    #load files from S3    
    download_path = {}
    for k in keys:
        download_path[k] = '/tmp/{}'.format(k)
        if not os.path.exists(download_path[k]):
            logger.debug('download %s'%(k))
            s3_client.download_file(S3_BUCKET_NAME, k, download_path[k])
        else:
            logger.debug('file `%s` already exists, skip download'%(download_path[k]))

    return download_path

download_keys = [MODEL_FILE, VENV_EXTRA_FILE]

logger.debug("download dependencies from S3")

try:
    download_paths = download_peripherals(download_keys)
except Exception as e:
    logger.error(traceback.format_exc())
    logger.error("ERROR: Unexpected error: Could not download dependencies from S3.")
    sys.exit()

logger.debug("unzip python dependencies: %s"%(download_paths[VENV_EXTRA_FILE]))

try:
    # unzip py dependencies from S3
    with open(download_paths[VENV_EXTRA_FILE],'rb') as tf:
        # rewind the file
        tf.seek(0)

        # Read the file as a zipfile and process the members
        with zipfile.ZipFile(tf, mode='r') as zipf:
            for zmember in zipf.infolist():
                if not os.path.exists('/tmp/lambda_packages/%s'%(zmember.filename)):
                    zipf.extract(zmember, "/tmp/lambda_packages/")

except Exception as e:
    logger.error(traceback.format_exc())
    logger.error("ERROR: Unexpected error: Could not unzip python dependencies.")
    sys.exit()

logger.debug("load shared libraries")

os.chdir('/tmp/lambda_packages/lib/')
for libfile in ['/tmp/lambda_packages/lib/libatlas.so.3',
                '/tmp/lambda_packages/lib/libcblas.so.3',
                '/tmp/lambda_packages/lib/libquadmath.so.0',
                '/tmp/lambda_packages/lib/libgfortran.so.3',
                '/tmp/lambda_packages/lib/libf77blas.so.3'
                ]:
    logger.debug('load lib: %s'%(libfile))
    ctypes.cdll.LoadLibrary(libfile)

for d, _, files in os.walk('/tmp/lambda_packages/lib'):
    for f in files:
        if f.endswith('.a'):
            continue
        logger.debug("load %s"%(os.path.join(d, f)))
        ctypes.cdll.LoadLibrary(os.path.join(d, f))

logger.debug("import downloaded python dependecies")

sys.path.append("/tmp/lambda_packages/")

import numpy as np

mnist_model = pickle.load(open(download_paths[MODEL_FILE],'rb'))

def predict(txbody):
    X = np.expand_dims(txbody['digit'], axis=0)
    return int(mnist_model.predict(X)[0])
    
def respond(err, res=None):
    return {
        'statusCode': '400' if err else '200',
        'body': err.message if err else json.dumps(res),
        'headers': {
            'Content-Type': 'application/json',
        },
    }

def lambda_handler(event, context):
    txbody_json = event['body']

    txbody = json.loads(txbody_json)
        
    return respond(False, {"prediction": predict(txbody)})
