#!/bin/bash

# http://logs.openstack.org/71/415171/1/check/gate-kolla-kubernetes-deploy-centos-binary-ceph-nv/4725106/console.html
# http://www.tecmint.com/setup-dns-cache-server-in-centos-7/

yum install -y epel-release

yum install -y crudini cyrus-sasl-devel jq libcurl-devel libffi-devel openssl-devel python34-devel bash-completion

yum install -y git vim unbound python-virtualenv ansible
yum group install -y "Development Tools"

ifconfig eth1 192.168.222.2/24

mkdir -p /etc/nodepool
echo "192.168.222.2" > /etc/nodepool/primary_node_private

export WORKSPACE=/home/jenkins/workspace/gate-kolla-kubernetes-deploy-centos-binary-ceph-nv

mkdir -p $WORKSPACE

cd $WORKSPACE

git clone https://github.com/openstack/kolla-kubernetes.git .
git checkout d4e2c0adb3f44af0dbdc5521f7878e2eba4fa7bf
git apply ~/kk8s.diff

mkdir -p $WORKSPACE/logs/

tools/setup_gate.sh deploy centos binary ceph centos-7 shell

echo "source <(kubectl completion bash)" >> ~/.bashrc
