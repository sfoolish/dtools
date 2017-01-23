#!/bin/bash

set -x

WORK_DIR=`cd ${BASH_SOURCE[0]%/*}/;pwd`
HOST_NAME=$1
IMAGE_NAME=$2
HOST_NAME=${HOST_NAME:-kmm0}
IMAGE_NAME=${IMAGE_NAME:-disk.img_image-pulled}

cd $WORK_DIR
source ../libvirt_tools/util.sh

pushd ../libvirt_tools/work/vm/$HOST_NAME
virsh destroy $HOST_NAME || true

if [ -f $IMAGE_NAME ]; then
    cp $IMAGE_NAME disk.img
elif [ -f ../../cache/$IMAGE_NAME ]; then
    cp ../../cache/$IMAGE_NAME disk.img
elif [ -f /opt/kk8s/$IMAGE_NAME ]; then
    cp /opt/kk8s/$IMAGE_NAME disk.img
fi

virsh start $HOST_NAME
popd

wait_ok $HOST_NAME 100

