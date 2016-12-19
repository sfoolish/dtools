#!/bin/bash

# http://docs.openstack.org/developer/kolla/newton/quickstart.html

set -x

# install openstack client
yum install -y python-devel libffi-devel openssl-devel gcc
pip install -U python-openstackclient python-neutronclient

# generate openrc
kolla-ansible post-deploy

# generate ssh key if it is not exist
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
fi

# run init script
. /etc/kolla/admin-openrc.sh
/usr/share/kolla/init-runonce

