#!/bin/bash

set -x

SCRIPT_DIR=`cd ${BASH_SOURCE[0]%/*};pwd`
WORK_DIR=${SCRIPT_DIR}/work

vm_name=$1

if [[ $vm_name == "" ]]; then
    echo "Please Run: $0 <vm name>"
    exit 1
fi

pushd $SCRIPT_DIR
source ./util.sh

if [[ ! -d $WORK_DIR/vm/$vm_name ]]; then
    echo "VM $vm_name does not exist !!!"
fi

pushd $WORK_DIR/vm/$vm_name
virsh destroy $vm_name
sleep 1
# restore vm image
cp disk.img_clean_with_key disk.img
virsh start $vm_name
wait_ok $vm_name 100
popd

popd
