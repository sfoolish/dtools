./k8s-create-vms.sh

scp setup_kubernetes.sh wait_for_kube_control_plane.sh km0:
ssh km0
rm -rf /etc/yum.repos.d/*
cat << "EOF" > /etc/yum.repos.d/mirrors.repo
[base]
name=base
baseurl=http://192.168.21.2:8888/centos_repos/base/
gpgcheck=0

[extras]
name=extras
baseurl=http://192.168.21.2:8888/centos_repos/extras/
gpgcheck=0

[updates]
name=updates
baseurl=http://192.168.21.2:8888/centos_repos/updates/
gpgcheck=0

[epel]
name=epel
baseurl=http://192.168.21.2:8888/centos_repos/epel/
gpgcheck=0

EOF

ifconfig eth1 192.168.222.222/24
mkdir -p /etc/nodepool/
echo "192.168.222.222" > /etc/nodepool/primary_node_private

./setup_kubernetes.sh master

