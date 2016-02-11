#!/bin/bash

apt-get update && \
apt-get install -y \
    curl \
    genisoimage \
    libvirt-bin \
    qemu-kvm \
    wget

