#!/bin/bash

# http://docs.openstack.org/developer/kolla/newton/quickstart.html

set -x

yum install -y epel-release
yum install -y python-pip
yum install -y vim wget
pip install -U pip

curl -sSL https://get.docker.io | bash
echo 'INSECURE_REGISTRY="--insecure-registry 192.168.122.71:4000"' > /etc/sysconfig/docker

tee /etc/systemd/system/docker.service <<-'EOF'
# CentOS
[Service]
MountFlags=shared
EnvironmentFile=/etc/sysconfig/docker
ExecStart=/usr/bin/docker daemon $INSECURE_REGISTRY
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

#kolla-genpwd
#
#sed -i -e "s/^kolla_internal_vip_address.*/kolla_internal_vip_address: \"192.168.122.133\"/g" \
#    -e "s/^#network_interface:.*/network_interface: \"eth0\"/g" \
#    /etc/kolla/globals.yml
#
#date
#kolla-ansible prechecks
#date
#kolla-ansible pull
#date
#kolla-ansible deploy
#date
for i in kolla/centos-binary-heat-api \
         kolla/centos-binary-heat-api-cfn \
         kolla/centos-binary-heat-engine \
         kolla/centos-binary-nova-compute \
         kolla/centos-binary-neutron-server \
         kolla/centos-binary-nova-libvirt \
         kolla/centos-binary-neutron-openvswitch-agent \
         kolla/centos-binary-neutron-l3-agent \
         kolla/centos-binary-neutron-dhcp-agent \
         kolla/centos-binary-neutron-metadata-agent \
         kolla/centos-binary-nova-ssh \
         kolla/centos-binary-nova-conductor \
         kolla/centos-binary-keystone \
         kolla/centos-binary-nova-api \
         kolla/centos-binary-nova-scheduler \
         kolla/centos-binary-nova-novncproxy \
         kolla/centos-binary-nova-consoleauth \
         kolla/centos-binary-glance-api \
         kolla/centos-binary-glance-registry \
         kolla/centos-binary-horizon \
         kolla/centos-binary-kolla-toolbox \
         kolla/centos-binary-mariadb \
         kolla/centos-binary-openvswitch-db-server \
         kolla/centos-binary-openvswitch-vswitchd \
         kolla/centos-binary-heka \
         kolla/centos-binary-rabbitmq \
         kolla/centos-binary-haproxy \
         kolla/centos-binary-keepalived \
         kolla/centos-binary-memcached \
         kolla/centos-binary-cron; do
    docker pull ${i}:3.0.1
done

