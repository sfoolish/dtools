#!/bin/bash
set -x

CURRENT_DIR=$(cd ${BASH_SOURCE[0]%/*}/;pwd)
COMPASS_DIR=${CURRENT_DIR}/../
WORK_DIR=$COMPASS_DIR/work/deploy
UNATTENDE_VM_DIR=$WORK_DIR/vm/unattended
UNATTENDED_ISO_URL=file://$COMPASS_DIR/work/build/iso/output/ubuntu-16.04.4-server-amd64-unattended.iso


source $COMPASS_DIR/env.conf
source $COMPASS_DIR/basics.sh

function prepare_work_env() {
    # prepare work dir
    mkdir -p $UNATTENDE_VM_DIR

    chmod -R 755 $WORK_DIR
}

function launch_unattended_vm() {
    sudo virsh destroy unattended
    sudo virsh undefine unattended
    sleep 10
    qemu-img create -f qcow2 -o preallocation=metadata $UNATTENDE_VM_DIR/disk.img 100G
    curl $UNATTENDED_ISO_URL -o $UNATTENDE_VM_DIR/unattended.iso

    # create vm xml
    sed -e "s#REPLACE_IMAGE#$UNATTENDE_VM_DIR/disk.img#g" \
        -e "s#REPLACE_ISO#$UNATTENDE_VM_DIR/unattended.iso#g" \
        $COMPASS_DIR/util/unattended.xml \
        > $UNATTENDE_VM_DIR/libvirt.xml

    sudo virsh define $UNATTENDE_VM_DIR/libvirt.xml
    sudo virsh start unattended
    virsh dumpxml unattended | grep vnc
}

export IS_VM_BOOT_ISO="true"
./create_unattended-iso.sh
prepare_work_env
launch_unattended_vm

