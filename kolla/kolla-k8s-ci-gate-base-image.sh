#!/bin/bash

ifconfig eth1 192.168.222.2/24
ssh kmn1 ifconfig eth1 192.168.222.3/24
ssh kmn2 ifconfig eth1 192.168.222.4/24

cat << "EEOF" > /etc/nodepool/sub_nodes_private
192.168.222.3
192.168.222.4
EEOF

cd /home/jenkins/workspace/gate-kolla-kubernetes-deploy-centos-binary-ceph-nv/

git checkout ./
git pull

git apply ~/setup_gate.diff

sed  -i -e "s/180/360/g" tools/wait_for_pods.sh
sed  -i -e "s/240/480/g" tools/setup_gate.sh
sed  -i -e "s/240/480/g" tools/setup_gate_iscsi.sh
sed  -i -e "s/240/480/g" tools/setup_rbd_volumes.sh

cat << EOF > tests/bin/fix_gate_iptables.sh
#!/bin/bash -xe

echo "cleaned by sf"

EOF

date | ts '[%Y-%m-%d %H:%M:%S]' | tee -a ~/deploy.log;\
./tools/setup_gate.sh deploy centos binary ceph-multi centos-7-2-node shell 3 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a ~/deploy.log
date | ts '[%Y-%m-%d %H:%M:%S]' | tee -a ~/deploy.log

