#!/bin/bash

SCRIPT_DIR=`cd ${BASH_SOURCE[0]%/*};pwd`
WORK_DIR=${SCRIPT_DIR}/work
host_vm_dir=$WORK_DIR/vm
source ./env_config.sh


function download_iso()
{
    mkdir -p ${WORK_DIR}/cache
    curl --connect-timeout 10 -o ${WORK_DIR}/cache/$IMAGE_NAME $IMAGE_URL
    qemu-img resize ${WORK_DIR}/cache/$IMAGE_NAME +500G
}

apt-get update && \
apt-get install -y \
    curl \
    genisoimage \
    libvirt-bin \
    qemu-kvm \
    wget

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
fi

mkdir -p $WORK_DIR
download_iso

