#!bin/bash

# install docker
curl -sSL https://get.docker.io | bash

# configure docker daemon
mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF
systemctl daemon-reload
systemctl restart docker

# configure docker registry
docker run -d -p 4000:5000 --restart=always --name registry registry:2

# pull docker images
docker pull gcr.io/kubernetes-helm/tiller:v2.1.3
docker pull docker.io/kolla/centos-binary-kubernetes-entrypoint:3.0.1
docker pull gcr.io/google_containers/kube-controller-manager-amd64:v1.5.1
docker pull gcr.io/google_containers/kube-apiserver-amd64:v1.5.1
docker pull gcr.io/google_containers/kube-proxy-amd64:v1.5.1
docker pull gcr.io/google_containers/kube-scheduler-amd64:v1.5.1
docker pull gcr.io/google_containers/etcd-amd64:3.0.14-kubeadm
docker pull gcr.io/google_containers/kubedns-amd64:1.9
docker pull gcr.io/google_containers/dnsmasq-metrics-amd64:1.0
docker pull docker.io/kolla/centos-binary-kolla-toolbox:3.0.1
docker pull docker.io/kolla/centos-binary-mariadb:3.0.1
docker pull docker.io/kolla/centos-binary-rabbitmq:3.0.1
docker pull gcr.io/google_containers/kube-dnsmasq-amd64:1.4
docker pull gcr.io/google_containers/kube-discovery-amd64:1.0
docker pull gcr.io/google_containers/exechealthz-amd64:1.2
docker pull docker.io/calico/cni:v1.4.2
docker pull quay.io/coreos/etcd:v3.0.9
docker pull quay.io/calico/node:v0.22.0
docker pull docker.io/kfox1111/centos-binary-kolla-toolbox:trunk-sometime
docker pull quay.io/coreos/flannel:v0.6.1
docker pull docker.io/calico/kube-policy-controller:v0.3.0
docker pull docker.io/kolla/centos-binary-cinder-api:2.0.2
docker pull docker.io/kolla/centos-binary-cinder-volume:2.0.2
docker pull docker.io/kolla/centos-binary-cinder-scheduler:2.0.2
docker pull docker.io/kolla/centos-binary-glance-api:2.0.2
docker pull docker.io/kolla/centos-binary-glance-registry:2.0.2
docker pull docker.io/kolla/centos-binary-nova-libvirt:2.0.2
docker pull docker.io/kolla/centos-binary-neutron-server:2.0.2
docker pull docker.io/kolla/centos-binary-neutron-metadata-agent:2.0.2
docker pull docker.io/kolla/centos-binary-nova-compute:2.0.2
docker pull docker.io/kolla/centos-binary-neutron-openvswitch-agent:2.0.2
docker pull docker.io/kolla/centos-binary-neutron-l3-agent:2.0.2
docker pull docker.io/kolla/centos-binary-neutron-dhcp-agent:2.0.2
docker pull docker.io/kolla/centos-binary-nova-conductor:2.0.2
docker pull docker.io/kolla/centos-binary-nova-consoleauth:2.0.2
docker pull docker.io/kolla/centos-binary-nova-api:2.0.2
docker pull docker.io/kolla/centos-binary-nova-scheduler:2.0.2
docker pull docker.io/kolla/centos-binary-nova-novncproxy:2.0.2
docker pull docker.io/kolla/centos-binary-horizon:2.0.2
docker pull docker.io/kolla/centos-binary-keystone:2.0.2
docker pull docker.io/kolla/centos-binary-ceph-mon:2.0.2
docker pull docker.io/kolla/centos-binary-ceph-osd:2.0.2
docker pull docker.io/kolla/centos-binary-openvswitch-vswitchd:2.0.2
docker pull docker.io/kolla/centos-binary-openvswitch-db-server:2.0.2
docker pull docker.io/kolla/centos-binary-memcached:2.0.2
docker pull docker.io/kolla/centos-binary-haproxy:2.0.2
docker pull gcr.io/google_containers/pause-amd64:3.0
docker pull gcr.io/google_containers/etcd:2.2.1

docker images | grep -v TAG | grep -v local | awk '{print $1,$2}' | while read -r image tag; do
    docker tag ${image}:${tag} localhost:4000/${image}:${tag}
    docker push localhost:4000/${image}:${tag}
done

