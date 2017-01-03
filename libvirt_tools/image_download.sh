#!/bin/bash

IMAGE_URL="http://cloud.centos.org/centos/7/atomic/images/CentOS-Atomic-Host-7-GenericCloud.qcow2 "
IMAGE_URL+="http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2 "
IMAGE_URL+="https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img "
IMAGE_URL+="https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img "

for url in $IMAGE_URL; do
    curl -O $url
done

