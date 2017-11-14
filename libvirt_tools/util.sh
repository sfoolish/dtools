#!/bin/bash
##############################################################################
# Copyright (c) 2015 Huawei Technologies Co.,Ltd and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

ssh_args="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa"

function download_iso()
{
    mkdir -p ${WORK_DIR}/cache
    curl --connect-timeout 10 -o ${WORK_DIR}/cache/$IMAGE_NAME $IMAGE_URL
    IMAGE_SIZE=$(qemu-img info ${WORK_DIR}/cache/$IMAGE_NAME | awk 'match($0,/virtual size/) {print int(strtonum($3))}')
    if [ $IMAGE_SIZE -lt 500 ]; then
        qemu-img resize ${WORK_DIR}/cache/$IMAGE_NAME +500G
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

function tear_down_clean_machines() {
    for i in $CLEAN_HOSTS; do
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
             "ip ${IPADDR_PREFIX}$((IPADDR_START+i))" \
             "mac ${mac_array[$i]}"
        vm_dir=$host_vm_dir/$host
        mkdir -p $vm_dir

        cp ${WORK_DIR}/cache/$IMAGE_NAME $vm_dir

        # create seed.iso
        sed -e "s/REPLACE_IPADDR/${IPADDR_PREFIX}$((IPADDR_START+i))/g" \
            -e "s/REPLACE_GATEWAY/${IPADDR_PREFIX}1/g" \
            -e "s/REPLACE_HOSTNAME/${host}/g" \
            -e "s/REPLACE_NIC_NAME/${NIC_NAME}/g" \
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

        qemu-img create -f qcow2 $vm_dir/disk-b.img 20G
        qemu-img create -f qcow2 $vm_dir/disk-c.img 20G
        # create vm xml
        sed -e "s/REPLACE_MEM/$VIRT_MEM/g" \
            -e "s/REPLACE_CPU/$VIRT_CPUS/g" \
            -e "s/REPLACE_NAME/$host/g" \
            -e "s#REPLACE_IMAGE_A#$vm_dir/disk.img#g" \
            -e "s#REPLACE_IMAGE_B#$vm_dir/disk-b.img#g" \
            -e "s#REPLACE_IMAGE_C#$vm_dir/disk-c.img#g" \
            -e "s#REPLACE_SEED_IMAGE#$vm_dir/seed.iso#g" \
            -e "s/REPLACE_MAC_ADDR/${mac_array[$i]}/g" \
            -e "s/REPLACE_NET_MGMT_NET/mgmt-net/g" \
            libvirt_template.xml \
            > $vm_dir/libvirt.xml

        sudo virsh define $vm_dir/libvirt.xml
        sudo virsh start $host

        ssh-keygen -f "/root/.ssh/known_hosts" -R ${host}
        sed -i "/${IPADDR_PREFIX}$((IPADDR_START+i))/d" /etc/hosts
        sed -i "/${host}/d" /etc/hosts
        echo "${IPADDR_PREFIX}$((IPADDR_START+i)) ${host}" >> /etc/hosts
        let i=i+1
    done
    IFS=$old_ifs
    rm -rf meta-data user-data seed.iso
}

function launch_clean_host_vms() {
    old_ifs=$IFS
    IFS=,
    tear_down_clean_machines
    i=0
    for host in $CLEAN_HOSTS; do
        echo "creating vm disk for instance $host"
        vm_dir=$host_vm_dir/$host
        mkdir -p $vm_dir

        qemu-img create -f qcow2 -o preallocation=metadata $vm_dir/disk.img 500G
        qemu-img create -f qcow2 -o preallocation=metadata $vm_dir/disk-b.img 100G
        qemu-img create -f qcow2 -o preallocation=metadata $vm_dir/disk-c.img 100G
        # create vm xml
        sed -e "s/REPLACE_MEM/$VIRT_MEM/g" \
            -e "s/REPLACE_CPU/$VIRT_CPUS/g" \
            -e "s/REPLACE_NAME/$host/g" \
            -e "s#REPLACE_IMAGE_A#$vm_dir/disk.img#g" \
            -e "s#REPLACE_IMAGE_B#$vm_dir/disk-b.img#g" \
            -e "s#REPLACE_IMAGE_C#$vm_dir/disk-c.img#g" \
            -e "s/REPLACE_NET_MGMT_NET/mgmt-net/g" \
            libvirt_clean_template.xml \
            > $vm_dir/libvirt.xml

        sudo virsh define $vm_dir/libvirt.xml
        sudo virsh start $host

        let i=i+1
    done
    IFS=$old_ifs
}


function wait_ok() {
    MGMT_IP=$1
    set +x
    echo "wait_ok enter $MGMT_IP"
    ssh-keygen -f "/root/.ssh/known_hosts" -R $MGMT_IP >/dev/null 2>&1
    retry=0
    while true
    do
        ssh $ssh_args ${USER_NAME}@$MGMT_IP "exit" >/dev/null 2>&1
        [ $? -eq 0 ] && break

        echo "os install time used: $((retry*100/$2))%"
        sleep 1
        let retry+=1
        if [[ $retry -ge $2 ]];then
            # first try
            ssh $ssh_args ${USER_NAME}@$MGMT_IP "exit"
            # second try
            ssh $ssh_args ${USER_NAME}@$MGMT_IP "exit"
            exit_status=$?
            if [[ $exit_status == 0 ]]; then
                echo "final ssh login compass success !!!"
                break
            fi
            echo "final ssh retry failed with status: " $exit_status
            echo "os install time out"
            return
        fi
    done
    set -x
    echo "wait_ok exit"
}

function root_auth_setup()
{
    MGMT_IP=$1
    ssh -tt $ssh_args ${USER_NAME}@$MGMT_IP "
        sudo sed -i -e 's/ssh-rsa/\n&/g' /root/.ssh/authorized_keys
        sudo sed -i -e '/echo/d' /root/.ssh/authorized_keys
    "
}

function set_all_root_auth()
{
    old_ifs=$IFS
    IFS=,
    i=0
    for host in $HOSTNAMES; do
        IFS=$old_ifs
        wait_ok "${IPADDR_PREFIX}$((IPADDR_START+i))" 100
        root_auth_setup "${IPADDR_PREFIX}$((IPADDR_START+i))"
        let i=i+1
        IFS=,
    done

    IFS=$old_ifs
}

function root_ssh_config_setup()
{
    MGMT_IP=$1
    scp $ssh_args /root/.ssh/config /root/.ssh/id_rsa* $MGMT_IP:/root/.ssh/
    scp $ssh_args /etc/hosts $MGMT_IP:/etc/hosts
    ssh -tt $ssh_args $MGMT_IP 'sed -i -e "s/Defaults    requiretty/Defaults    \!requiretty/g" /etc/sudoers'
}

function set_all_ssh_config()
{
    old_ifs=$IFS
    IFS=,
    i=0
    for host in $HOSTNAMES; do
        IFS=$old_ifs
        root_ssh_config_setup "${IPADDR_PREFIX}$((IPADDR_START+i))"
        let i=i+1
        IFS=,
    done

    IFS=$old_ifs
}

function clear_all_seed_cdrom_for_vm()
{
    old_ifs=$IFS
    IFS=,
    i=0
    for host in $HOSTNAMES; do
        IFS=$old_ifs
        vm_dir=$host_vm_dir/$host
        grep "cdrom" $vm_dir/libvirt.xml
        if [ $? != 0 ]; then
            continue
        fi
        #sudo virsh destroy $host
        ssh -tt $ssh_args "${IPADDR_PREFIX}$((IPADDR_START+i))" "
            hostname $host
            echo $host > /etc/hostname
            /etc/init.d/network restart
            sync; sync;
            poweroff
        "

        sleep 3
        # force destroy if not finish yet
        sudo virsh destroy $host || true
        sudo virsh undefine $host
        cp $vm_dir/disk.img $vm_dir/disk.img_clean_with_key
        cp $vm_dir/libvirt.xml $vm_dir/libvirt.xml_seed.iso
        sudo sed -i '/cdrom/,/disk/d' $vm_dir/libvirt.xml
        sudo virsh define $vm_dir/libvirt.xml
        sudo virsh start $host
        let i=i+1
        IFS=,
    done

    IFS=$old_ifs
}

function wait_all_ok()
{
    old_ifs=$IFS
    IFS=,
    i=0
    for host in $HOSTNAMES; do
        IFS=$old_ifs
        wait_ok "${IPADDR_PREFIX}$((IPADDR_START+i))" 100
        let i=i+1
        IFS=,
    done

    IFS=$old_ifs
}
