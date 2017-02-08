#!/bin/bash

ifconfig eth1 192.168.222.2/24

cd /home/jenkins/workspace/gate-kolla-kubernetes-deploy-centos-binary-ceph-nv/

git checkout ./
git pull

sed -i -e "s/180/360/g" tools/wait_for_pods.sh
sed -i -e "s/240/480/g" tools/setup_gate.sh
sed -i -e "s/240/480/g" tools/setup_gate_iscsi.sh
sed -i -e "s/240/480/g" tools/setup_rbd_volumes.sh

cat << EOF > tests/bin/fix_gate_iptables.sh
#!/bin/bash -xe

echo "cleaned by sf"

EOF

date |tee -a ~/deploy.log;\
./tools/setup_gate.sh deploy centos binary ceph centos-7 shell 3 2>&1 | tee -a ~/deploy.log;\
date |tee -a ~/deploy.log

