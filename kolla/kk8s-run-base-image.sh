#!/bin/bash

set -x

WORK_DIR=`cd ${BASH_SOURCE[0]%/*}/;pwd`
HOST_NAME=$1
IMAGE_NAME=$2
HOST_NAME=${HOST_NAME:-kmaster}
IMAGE_NAME=${IMAGE_NAME:-disk.img_image-pulled}

cd $WORK_DIR
source ../libvirt_tools/util.sh

pushd ../libvirt_tools/work/vm/$HOST_NAME
virsh destroy $HOST_NAME || true
cp $IMAGE_NAME disk.img
virsh start $HOST_NAME
popd

wait_ok $HOST_NAME 100

scp kk8s-base-image-gate.sh $HOST_NAME:~/

ssh -t $HOST_NAME ~/kk8s-base-image-gate.sh

