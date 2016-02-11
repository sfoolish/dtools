#!/bin/bash
##############################################################################
# Copyright (c) 2015 Huawei Technologies Co.,Ltd and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# copy from bottlenecks/utils/rubbos_dev_env_setup/deploy.sh

set -x

SCRIPT_DIR=`cd ${BASH_SOURCE[0]%/*};pwd`
WORK_DIR=${SCRIPT_DIR}/work

mkdir -p $WORK_DIR

source ./env_config.sh

host_vm_dir=$WORK_DIR/vm


function download_iso()
{
    mkdir -p ${WORK_DIR}/cache
    curl --connect-timeout 10 -o ${WORK_DIR}/cache/$IMAGE_NAME $IMAGE_URL
}


function tear_down_machines() {
    for i in $HOSTNAMES; do
        echo "tear down machine:" $i
        sudo virsh destroy $i
        sudo virsh undefine $i
        rm -rf $host_vm_dir/$i
    done
}


function get_host_macs() {
    local mac_generator=${SCRIPT_DIR}/mac_generator.sh
    local machines=

    chmod +x $mac_generator
    mac_array=$($mac_generator $VIRT_NUMBER)
    machines=$(echo $mac_array)

    echo $machines
}

function launch_host_vms() {
    mac_array=($(get_host_macs))

    echo ${mac_array[2]}
    echo ${mac_array[*]}

    old_ifs=$IFS
    IFS=,
    tear_down_machines
    echo "bringing up vms ${mac_array[*]}"
    i=0
    for host in $HOSTNAMES; do
        echo "creating vm disk for instance $host" \
             "ip ${IPADDR_PREFIX}$((i+11))" \
             "mac ${mac_array[$i]}"
        vm_dir=$host_vm_dir/$host
        mkdir -p $vm_dir

        cp ${WORK_DIR}/cache/$IMAGE_NAME $vm_dir

        # create seed.iso
        sed -e "s/REPLACE_IPADDR/${IPADDR_PREFIX}$((i+11))/g" \
            -e "s/REPLACE_GATEWAY/${IPADDR_PREFIX}1/g" \
            -e "s/REPLACE_HOSTNAME/${host}/g" \
            meta-data_template \
            > meta-data

        if [ -f ~/.ssh/id_rsa.pub ]; then
            sed -e "/ssh_authorized_keys/a\  - $(cat ~/.ssh/id_rsa.pub)" user-data_template \
                > user-data
        else
            cp user-data_template user-data
        fi

        genisoimage  -output seed.iso -volid cidata -joliet -rock user-data meta-data
        cp seed.iso $vm_dir

        # create vm xml
        sed -e "s/REPLACE_MEM/$VIRT_MEM/g" \
            -e "s/REPLACE_CPU/$VIRT_CPUS/g" \
            -e "s/REPLACE_NAME/$host/g" \
            -e "s#REPLACE_IMAGE#$vm_dir/disk.img#g" \
            -e "s#REPLACE_SEED_IMAGE#$vm_dir/seed.iso#g" \
            -e "s/REPLACE_MAC_ADDR/${mac_array[$i]}/g" \
            libvirt_template.xml \
            > $vm_dir/libvirt.xml

        sudo virsh define $vm_dir/libvirt.xml
        sudo virsh start $host
        let i=i+1
    done
    IFS=$old_ifs
    rm -rf meta-data user-data seed.iso
}


download_iso
launch_host_vms

set +x

