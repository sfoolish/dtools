#!/bin/bash

LOCAL_BASE_URL="http://192.168.21.2:8888"
IMAGE_URL="http://cloud.centos.org/centos/7/atomic/images/CentOS-Atomic-Host-7-GenericCloud.qcow2 "
IMAGE_URL+="http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2 "
IMAGE_URL+="https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img "
IMAGE_URL+="https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img "

for url in $IMAGE_URL; do
    curl -O $url
done

# genarate image links
rm -rf index.html
for i in $(ls -l | grep -v image | grep -v tot | awk '{print $9}'); do
    echo ${LOCAL_BASE_URL}/${i} >> index.html
done

