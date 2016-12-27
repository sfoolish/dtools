#!/bin/bash

yum install -y \
    https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.rpm

yum install -y libvirt \
               libxslt-devel \
               libxml2-devel \
               libvirt-devel \
               libguestfs-tools-c \
               ruby-devel \
               gcc \
               git \
               git-review \
               gcc-c++
vagrant plugin install vagrant-libvirt

sudo bash -c 'cat << EOF > /etc/polkit-1/rules.d/80-libvirt-manage.rules
polkit.addRule(function(action, subject) {
if (action.id == "org.libvirt.unix.manage" && subject.local && subject.active && subject.isInGroup("wheel")) {
  return polkit.Result.YES;
}
});
EOF'

sudo usermod -aG libvirt $USER

sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo yum install -y epel-release
sudo yum install -y ansible

cd /opt/
git clone https://github.com/att-comdev/halcyon-vagrant-kubernetes

cd halcyon-vagrant-kubernetes/

git submodule init
git submodule update

./setup-halcyon.sh \
    --k8s-config kolla \
    --k8s-version v1.4.6 \
    --guest-os centos

vagrant up
./get-k8s-creds.sh

vagrant ssh kube1
vagrant destroy

