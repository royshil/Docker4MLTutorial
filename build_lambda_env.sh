#!/bin/bash
#
#   description: This script is used to build the AWS lambda environment for running our risk service.
#   author: Roy Shilkrot
#   date: 11/13/2017
#
#   Copyright @ AI Detectcion 2017
#
#
#   This script is meant to be run on an instance that resembles AWS lambda execution environment,
#   i.e. amazon linux.
#
set -ex

yum update -y
yum install -y \
    atlas-devel \
    atlas-sse3-devel \
    blas-devel \
    gcc \
    gcc-c++ \
    lapack-devel \
    python27-devel \
    python27-virtualenv \
    findutils \
    zip

do_pip () {
    pip install --upgrade pip wheel
    pip install --use-wheel --no-binary --install-option="-j 4" numpy numpy
    pip install --use-wheel --no-binary --install-option="-j 4" scipy scipy
    pip install --use-wheel sklearn
    pip install --use-wheel imblearn
    pip install --use-wheel -t $VIRTUAL_ENV/lib64/python2.7/site-packages/ ua_parser
    pip install --use-wheel pandas
    pip install --use-wheel -t $VIRTUAL_ENV/lib64/python2.7/site-packages/ pytz
    pip install --use-wheel -t $VIRTUAL_ENV/lib64/python2.7/site-packages/ sklearn_pandas
    pip install --use-wheel -t $VIRTUAL_ENV/lib64/python2.7/site-packages/ xgboost
}

strip_virtualenv () {
    mkdir -p $VIRTUAL_ENV/outputs

    echo "venv original size $(du -sh $VIRTUAL_ENV | cut -f1)"
    find $VIRTUAL_ENV/lib64/python2.7/site-packages/ -name "*.so" | xargs strip
    echo "venv stripped size $(du -sh $VIRTUAL_ENV | cut -f1)"

    pushd $VIRTUAL_ENV/lib64/python2.7/site-packages/ && zip -r -9 -q $VIRTUAL_ENV/outputs/venv.zip * ; popd
    echo "site-packages compressed size $(du -sh $VIRTUAL_ENV/outputs/venv.zip | cut -f1)"

    pushd $VIRTUAL_ENV && zip -r -q $VIRTUAL_ENV/outputs/full-venv.zip * ; popd
    echo "venv compressed size $(du -sh $VIRTUAL_ENV/outputs/full-venv.zip | cut -f1)"
}

shared_libs () {
    libdir="$VIRTUAL_ENV/lib64/python2.7/site-packages/lib/"
    mkdir -p $VIRTUAL_ENV/lib64/python2.7/site-packages/lib || true
    cp /usr/lib64/atlas/* $libdir
    cp /usr/lib64/libquadmath.so.0 $libdir
    cp /usr/lib64/libgfortran.so.3 $libdir
}

main () {
    /usr/bin/virtualenv \
        --python /usr/bin/python /lambda_build \
        --always-copy \
        --no-site-packages
    source /lambda_build/bin/activate

    do_pip

    shared_libs

    strip_virtualenv
}
main
