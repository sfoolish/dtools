#!/bin/bash

apt-get update && \
apt-get install -y \
    curl \
    genisoimage \
    libvirt-bin \
    qemu-kvm \
    moreutils \
    gawk \
    wget

# generate ssh key if it is not exist
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
fi

