#!/bin/bash

source openrc

## Test launch an instance on infra1-utility-container

function prepare_env() {
    # check if basic resources like flavor, secgroup, image is already set
    nova flavor-list | grep tiny
    [[ "$?" == "0" ]] && return
    
    nova flavor-create m1.tiny 1 1024 0 1
    nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
    nova secgroup-add-rule default tcp 22 22 0.0.0.0/0

    wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
    glance image-create --name "cirros-0.3.3" \
        --file cirros-0.3.4-x86_64-disk.img \
        --disk-format qcow2 \
        --container-format bare
}

prepare_env

openstack network create  --share \
  --provider-physical-network flat \
  --provider-network-type flat provider

openstack subnet create --network provider \
  --allocation-pool start=192.168.122.50,end=192.168.122.150\
  --dns-nameserver 8.8.4.4 --gateway 192.168.122.1 \
  --subnet-range 192.168.122.0/24 subprovider
neutron net-update provider --router:external

openstack network create selfservice
openstack subnet create --network selfservice \
  --dns-nameserver 8.8.4.4 --gateway 10.10.10.1 \
  --subnet-range 10.10.10.0/24 subselfservice

openstack router create router
neutron router-interface-add router subselfservice
neutron router-gateway-set router provider

nova boot --flavor m1.tiny --image cirros-0.3.3 --nic net-id=$(neutron net-list | grep selfservice | awk '{print $2}') --security-group default demo1

neutron floatingip-create provider
demo1_floating_ip=$(neutron floatingip-create provider | grep floating_ip_address | awk '{print $4}')
nova floating-ip-associate demo1 $demo1_floating_ip

ping -c 3 $demo1_floating_ip
while [ "$?" != "0" ]
do
    ping -c 3 $demo1_floating_ip
done

nova floating-ip-disassociate demo1 $demo1_floating_ip

## Test clean

nova delete demo1

neutron floatingip-list | grep 192 | awk '{print $2}' | xargs neutron floatingip-delete

neutron router-gateway-clear router
neutron router-interface-delete router subselfservice
neutron subnet-delete subselfservice
neutron subnet-delete subprovider
neutron net-delete selfservice
neutron net-delete provider
neutron router-delete router

