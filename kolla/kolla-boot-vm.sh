#!/bin/bash

source /etc/kolla/admin-openrc.sh

ifconfig eth1 up
ifconfig br-ex 10.0.2.1/24

openstack server create \
    --image cirros \
    --flavor m1.tiny \
    --key-name mykey \
    --nic net-id=$(neutron net-list | grep demo-net | awk '{print $2}') \
    demo1


demo1_floating_ip=$(neutron floatingip-create public1 | grep floating_ip_address | awk '{print $4}')
nova floating-ip-associate demo1 $demo1_floating_ip

ping -c 3 $demo1_floating_ip
while [ "$?" != "0" ]
do
    ping -c 3 $demo1_floating_ip
done


function clean_vm_and_netwok()
{
	nova floating-ip-disassociate demo1 $demo1_floating_ip
    nova delete demo1

    neutron floatingip-list | grep 10 | awk '{print $2}' | xargs neutron floatingip-delete

    neutron router-gateway-clear demo-router
    neutron router-interface-delete demo-router demo-subnet
    neutron subnet-delete demo-subnet
    neutron subnet-delete 1-subnet
    neutron net-delete demo-net
    neutron net-delete public1
    neutron router-delete demo-router
}

