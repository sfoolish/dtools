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

function download_iso()
{
    mkdir -p ${WORK_DIR}/cache
    curl --connect-timeout 10 -o ${WORK_DIR}/cache/$IMAGE_NAME $IMAGE_URL
    IMAGE_SIZE=$(qemu-img info ${WORK_DIR}/cache/$IMAGE_NAME | awk 'match($0,/virtual size/) {print int(strtonum($3))}')
    if [ $IMAGE_SIZE -lt 50 ]; then
        qemu-img resize ${WORK_DIR}/cache/$IMAGE_NAME +50G
    fi
}


function setup_nat_net() {
    net_name=$1
    gw=$2
    mask=$3
    ip_start=$4
    ip_end=$5

    sudo virsh net-destroy $net_name
    sudo virsh net-undefine $net_name
    # create install network
    sed -e "s/REPLACE_BRIDGE/br_$net_name/g" \
        -e "s/REPLACE_NAME/$net_name/g" \
        -e "s/REPLACE_GATEWAY/$gw/g" \
        -e "s/REPLACE_MASK/$mask/g" \
        -e "s/REPLACE_START/$ip_start/g" \
        -e "s/REPLACE_END/$ip_end/g" \
        nat_template.xml \
        > $net_name.xml

    sudo virsh net-define $net_name.xml
    sudo virsh net-start $net_name
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
            -e "s#REPLACE_VM_LOGGING#$vm_dir/console.log#g" \
            -e "s/REPLACE_NET_MGMT_NET/mgmt-net/g" \
            libvirt_template.xml \
            > $vm_dir/libvirt.xml

        sudo virsh define $vm_dir/libvirt.xml
        sudo virsh start $host
        let i=i+1
    done
    IFS=$old_ifs
    rm -rf meta-data user-data seed.iso
}

function wait_ok() {
    MGMT_IP=$1
    set +x
    echo "wait_ok enter"
    ssh-keygen -f "/root/.ssh/known_hosts" -R $MGMT_IP >/dev/null 2>&1
    retry=0
    until timeout 1s ssh $ssh_args ubuntu@$MGMT_IP "exit" >/dev/null 2>&1
    do
        echo "os install time used: $((retry*100/$2))%"
        sleep 1
        let retry+=1
        if [[ $retry -ge $2 ]];then
            timeout 1s ssh $ssh_args ubuntu@$MGMT_IP "exit"
            echo "os install time out"
            exit 1
        fi
    done
    echo "wait_ok exit"
}

function root_auth_setup()
{
    MGMT_IP=$1
    ssh $ssh_args ubuntu@$MGMT_IP "
        sudo sed -ie 's/ssh-rsa/\n&/g' /root/.ssh/authorized_keys
        sudo sed -ie '/echo/d' /root/.ssh/authorized_keys
    "
}

source ./env_config.sh

SCRIPT_DIR=`cd ${BASH_SOURCE[0]%/*};pwd`
WORK_DIR=${SCRIPT_DIR}/work
ssh_args="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa"

mkdir -p $WORK_DIR
host_vm_dir=$WORK_DIR/vm


download_iso
setup_nat_net mgmt-net $MGMT_NET_GW $MGMT_NET_MASK $MGMT_NET_IP_START $MGMT_NET_IP_END
launch_host_vms

wait_ok "192.168.122.11" 25
root_auth_setup "192.168.122.11"

wait_ok "192.168.122.12" 25
root_auth_setup "192.168.122.12"


set +x

