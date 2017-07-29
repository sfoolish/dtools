#!/bin/bash

yum install -y \
    curl \
    libvirt \
    qemu-kvm \
    wget \
    genisoimage \
    moreutils \
    vim \
    git

service libvirtd restart

# generate ssh key if it is not exist
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
fi

