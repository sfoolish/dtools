#!/bin/bash

# http://docs.openstack.org/developer/kolla/newton/quickstart.html

set -x

yum install -y epel-release
yum install -y python-pip
yum install -y vim wget
pip install -U pip

curl -sSL https://get.docker.io | bash
mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF
systemctl daemon-reload
systemctl restart docker

yum install -y python-docker-py

# check if it is need to configure
# # Edit /etc/rc.local to add:
# mount --make-shared /run

yum install -y ntp
systemctl enable ntpd.service
systemctl start ntpd.service

systemctl stop libvirtd.service
systemctl disable libvirtd.service

yum install -y ansible

pip install kolla

cp -r /usr/share/kolla/etc_examples/kolla /etc/

docker run -d -p 4000:5000 --restart=always --name registry registry:2

cat << EOF >> /etc/hosts
192.168.122.71 centos-ansible
192.168.122.72 control01
192.168.122.73 control02
192.168.122.74 control03
192.168.122.75 network01
192.168.122.76 compute01
192.168.122.77 monitoring01
192.168.122.78 storage01
EOF

kolla-genpwd

sed -i -e "s/^kolla_internal_vip_address.*/kolla_internal_vip_address: \"192.168.122.133\"/g" \
    -e "s/^#network_interface:.*/network_interface: \"eth0\"/g" \
    /etc/kolla/globals.yml
#
#date
#kolla-ansible prechecks
#date
kolla-ansible pull

docker images | grep kolla | grep -v local | awk '{print $1,$2}' | while read -r image tag; do
    docker tag ${image}:${tag} localhost:4000/${image}:${tag}
    docker push localhost:4000/${image}:${tag}
done

#date
#kolla-ansible deploy
#date
