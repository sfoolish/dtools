
# local repo test on km0

- create km0 to build ppa

```bash
ssh km0 sed -i 's/keepcache=0/keepcache=1/g' /etc/yum.conf
scp ./comps.xml km0:/
scp ./ceph_key_release.asc km0:/
scp ./repo-create.sh km0:/
ssh km0 yum install createrepo tar yum-plugin-priorities yum-utils -y
```

- Create httpserver to host ppa

```bash
# Nginx image usage please refer to https://hub.docker.com/_/nginx/
docker run --name repo-nginx -v /opt/kk8s/nginx-content:/usr/share/nginx/html:ro -d -p 80:80 nginx
```

- reset km0 vm

```bash
../../libvirt_tools/vm_reset.sh km0
```

- Update local yum repo confiugre file, update and install docker/k8s related packages

```bash
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

yum update
yum -y install docker kubelet kubeadm kubectl kubernetes-cni ebtables
```

## compass4nfv local repo test

- create compass repo

* create centos vm with compass4nfv deploy scripts
* create the ppa by using `compass-repo-create.sh`

