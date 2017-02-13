#!/bin/bash -e

ifconfig eth1 192.168.222.222/24
mkdir -p /etc/nodepool/
echo "192.168.222.222" > /etc/nodepool/primary_node_private

if [ -f /etc/redhat-release ]; then
    cat > /tmp/setup.$$ <<"EOF"
set -x
setenforce 0
rm -rf /etc/yum.repos.d/*
cat << "EEOF" > /etc/yum.repos.d/k8s_ppa_repo.repo
[k8s_ppa_repo]
name=rhel - k8s_repo
proxy=_none_
baseurl=http://192.168.21.21/repo_mirror/centos7-k8s-ppa
enabled=1
gpgcheck=0
skip_if_unavailable=1
EEOF
yum install -y docker kubelet kubeadm kubectl kubernetes-cni ebtables
systemctl start kubelet
EOF
else
    cat > /tmp/setup.$$ <<"EOF"
apt-get install -y apt-transport-https
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni
EOF
fi
cat >> /tmp/setup.$$ <<"EOF"
systemctl start docker
EOF
if [ "$1" == "master" ]; then
    cat >> /tmp/setup.$$ <<"EOF"
[ -d /etc/kubernetes/manifests ] && rmdir /etc/kubernetes/manifests || true
kubeadm init --skip-preflight-checks --service-cidr 172.16.128.0/24 --api-advertise-addresses $(cat /etc/nodepool/primary_node_private) | tee /tmp/kubeout
grep 'kubeadm join --token' /tmp/kubeout | awk '{print $3}' | sed 's/[^=]*=//' > /etc/kubernetes/token.txt
grep 'kubeadm join --token' /tmp/kubeout | awk '{print $4}' > /etc/kubernetes/ip.txt
rm -f /tmp/kubeout
EOF
else
    cat >> /tmp/setup.$$ <<EOF
kubeadm join --token "$2" "$3" --skip-preflight-checks
EOF
fi
cat >> /tmp/setup.$$ <<"EOF"
sed -i 's/10.96.0.10/172.16.128.10/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
systemctl stop kubelet
systemctl restart docker
systemctl start kubelet
EOF
sudo bash /tmp/setup.$$
sudo docker ps -a

if [ "$1" == "master" ]; then
    count=0
    while true; do
        kubectl get pods > /dev/null 2>&1 && break || true
        sleep 1
        count=$((count + 1))
        [ $count -gt 30 ] && echo kube-apiserver failed to come back up. && exit -1
    done
fi

