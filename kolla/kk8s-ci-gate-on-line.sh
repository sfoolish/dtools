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

mkdir -p $WORKSPACE/logs/

sed  -ie "s/180/360/g" tools/wait_for_pods.sh

cat << EOF > tests/bin/fix_gate_iptables.sh
#!/bin/bash -xe

echo "cleaned by sf"

EOF

if [ "x$CREATE_BASE_IMG" == "xbase" ]; then
    sudo yum remove -y iscsi-initiator-utils
    sudo yum install -y bridge-utils

    # install docker kubelet
    setenforce 0
    cat <<"EOEF" > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOEF
    yum install -y docker kubelet kubeadm kubectl kubernetes-cni ebtables
    systemctl start kubelet
    systemctl start docker

    cat docker_images.txt | while read image; do
        docker pull $image
    done
else
    tools/setup_gate.sh deploy centos binary ceph centos-7 shell
fi

echo "source <(kubectl completion bash)" >> ~/.bashrc

