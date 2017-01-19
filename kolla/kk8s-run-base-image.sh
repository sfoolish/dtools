#!/bin/bash

cat << "EEOF" > deploy.sh
#!/bin/bash
ifconfig eth1 192.168.222.2/24
cd /home/jenkins/workspace/gate-kolla-kubernetes-deploy-centos-binary-ceph-nv/

cat << EOF > tools/pull_containers.sh
#!/bin/bash -xe
echo "cleaned by sf"
EOF

date |tee -a ~/deploy.log;\
./tools/setup_gate.sh deploy centos binary ceph centos-7 shell 2>&1 | tee -a ~/deploy.log;\
date |tee -a ~/deploy.log
EEOF

chmod +x deploy.sh
./deploy.sh

