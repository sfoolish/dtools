#!/bin/bash

set -x

WORK_DIR=`cd ${BASH_SOURCE[0]%/*}/;pwd`
HOST_NAME=$1
IMAGE_NAME=$2
HOST_NAME=${HOST_NAME:-kmaster}
IMAGE_NAME=${IMAGE_NAME:-disk.img_image-pulled}

cd $WORK_DIR

scp kolla-k8s-ci-gate-base-image.sh $HOST_NAME:~/

ssh -tt $HOST_NAME ~/kolla-k8s-ci-gate-base-image.sh

