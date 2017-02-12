## local repo test

- Create httpserver to host ppa

```bash
# Nginx image usage please refer to https://hub.docker.com/_/nginx/
docker run --name repo-nginx -v /opt/kk8s/nginx-content:/usr/share/nginx/html:ro -d -p 80:80 nginx
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

