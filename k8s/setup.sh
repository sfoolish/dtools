#!/bin/bash

CONFIG=ceph-multi

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
echo "192.168.122.102" > /etc/nodepool/sub_nodes_private
ssh 192.168.122.102 ifconfig eth1 192.168.222.223/24

function setup_packages {
    sudo yum clean all
    sudo yum remove -y iscsi-initiator-utils
    sudo yum install -y bridge-utils tftp
    sudo yum install -y lvm2 iproute
    sudo yum install -y crudini jq sshpass bzip2
    sudo yum install -y vim git
    (echo server:; echo "  interface: 172.19.0.1"; echo "  access-control: 0.0.0.0/0 allow") | \
        sudo /bin/bash -c "cat > /etc/unbound/conf.d/kubernetes.conf"
}

function setup_bridge {
    sudo brctl addbr dns0
    sudo ifconfig dns0 172.19.0.1 netmask 255.255.255.0
    sudo brctl addbr net2
    sudo ifconfig net2 172.22.0.1 netmask 255.255.255.0
    sudo modprobe br_netfilter || true
    sudo sh -c 'echo 0 > /proc/sys/net/bridge/bridge-nf-call-iptables'
    sudo systemctl restart unbound
    sudo systemctl status unbound
    sudo netstat -pnl
    sudo sed -i "s/127\.0\.0\.1/172.19.0.1/" /etc/resolv.conf
    sudo cat /etc/resolv.conf
}


function setup_iptables {
sudo iptables-save > $WORKSPACE/logs/iptables-before.txt
tests/bin/fix_gate_iptables.sh
}

# Installating required software packages
setup_packages

# Setting up iptables
#setup_iptables

# Setting up an interface and a bridge
setup_bridge

./setup_kubernetes.sh master

kubectl taint nodes --all=true  node-role.kubernetes.io/master:NoSchedule-

#
# Setting up networking on master, before slave nodes in multinode
# scenario will attempt to join the cluster
./setup_canal.sh

# Turn up kube-proxy logging enable only for debug
# kubectl -n kube-system get ds -l 'component=kube-proxy-amd64' -o json \
#   | sed 's/--v=4/--v=9/' \
#   | kubectl apply -f - && kubectl -n kube-system delete pods -l 'component=kube-proxy-amd64'

if [ "x$CONFIG" == "xceph-multi" ]; then
    NODES=1
    cat /etc/nodepool/sub_nodes_private | while read line; do
        NODES=$((NODES+1))
        echo $line
        ssh-keyscan $line >> ~/.ssh/known_hosts
        scp setup_kubernetes.sh $line:
        #scp tests/bin/fix_gate_iptables.sh $line:
        scp /usr/bin/kubectl $line:kubectl
        NODENAME=$(ssh -n $line hostname)
        #ssh -n $line bash fix_gate_iptables.sh
        #ssh -n $line sudo iptables-save > $WORKSPACE/logs/iptables-$line.txt
        ssh -n $line sudo setenforce 0
        ssh -n $line sudo yum remove -y iscsi-initiator-utils
        ssh -n $line sudo mv kubectl /usr/bin/
        ssh -n $line bash setup_kubernetes.sh slave "$(cat /etc/kubernetes/token.txt)" "$(cat /etc/kubernetes/ip.txt)" "$(cat /etc/kubernetes/cahash.txt)"
        set +xe
        count=0
        while true; do
          c=$(kubectl get nodes --no-headers=true | wc -l)
          [ $c -ge $NODES ] && break
          count=$((count+1))
          [ $count -gt 30 ] && break
          sleep 1
        done
        [ $count -gt 30 ] && echo Node failed to join. && exit -1
        set -xe
        kubectl get nodes
        kubectl label node $NODENAME kolla_compute=true
    done
fi

NODE=$(hostname -s)
kubectl label node $NODE kolla_controller=true

if [ "x$CONFIG" != "xceph-multi" ]; then
    kubectl label node $NODE kolla_compute=true
fi

./pull_containers.sh kube-system
./wait_for_pods.sh kube-system

./test_kube_dns.sh

# Setting up Helm
#setup_helm_common
./setup_helm.sh

