#!/bin/bash
##############################################################################
# Copyright (c) 2016-2017 HUAWEI TECHNOLOGIES CO.,LTD and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -ex

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
WORK_ISO_BUILD_DIR=$CURRENT_DIR/../work/build/iso
RELEASE=(16.04.4 14.04.5 14.04.4 14.04.3 14.04.2 14.04.1)
ISO_URL_BASE=http://192.168.21.2:8888
IS_VM_BOOT_ISO=${IS_VM_BOOT_ISO:-"false"}

sudo -v
if [ $? -ne 0 ]; then
    echo "No root privilege, exiting..."
    exit 1
fi

if [[ ! -f /etc/redhat-release ]]; then
    sudo apt-get install -y wget mkisofs
else
    sudo yum install -y wget mkisofs
fi

TEMP=`getopt -o v: --long version: -- "$@"`
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$TEMP"
while :; do
    case "$1" in
        -v|--version) export OS_VERSION=$2; shift 2;;
        --) shift; break;;
        *) echo "Internal error!" ; exit 1;;
    esac
done

OS_VERSION=${OS_VERSION:-16.04.4}
for i in ${RELEASE[@]}
do
    if [[ $i =~ $OS_VERSION.* ]]; then
        OS_VERSION=$i
        OS_FOUND="true"
        break
    fi
done

if [[ $OS_FOUND != "true" ]]; then
    echo "Unsupported OS Version"
    exit 1
fi

mkdir -p $WORK_ISO_BUILD_DIR/build_iso $WORK_ISO_BUILD_DIR/output

#if [[ $OS_VERSION == "14.04.5" ]]; then
#    ISO_URL=http://releases.ubuntu.com/14.04/ubuntu-14.04.5-server-amd64.iso
#else
#    ISO_URL=http://old-releases.ubuntu.com/releases/$OS_VERSION/ubuntu-$OS_VERSION-server-amd64.iso
#fi
ISO_URL=$ISO_URL_BASE/ubuntu-$OS_VERSION-server-amd64.iso

wget -nc $ISO_URL -O $WORK_ISO_BUILD_DIR/build_iso/ubuntu-$OS_VERSION-server-amd64.iso || true

mkdir -p $WORK_ISO_BUILD_DIR/build_iso/org_iso

if grep -qs $WORK_ISO_BUILD_DIR/build_iso/org_iso /proc/mounts; then
    sudo umount $WORK_ISO_BUILD_DIR/build_iso/org_iso
fi

sudo mount -o loop $WORK_ISO_BUILD_DIR/build_iso/ubuntu-$OS_VERSION-server-amd64.iso $WORK_ISO_BUILD_DIR/build_iso/org_iso

if [ -d $WORK_ISO_BUILD_DIR/build_iso/new_iso ]; then
    sudo rm -rf $WORK_ISO_BUILD_DIR/build_iso/new_iso
fi

sudo cp -rT $WORK_ISO_BUILD_DIR/build_iso/org_iso $WORK_ISO_BUILD_DIR/build_iso/new_iso
sudo cp -rT $CURRENT_DIR/seed/trusty-auto.seed $WORK_ISO_BUILD_DIR/build_iso/new_iso/preseed/auto.seed

if [ x"$IS_VM_BOOT_ISO" == "xtrue" ]; then
    sudo sed -i -e 's|sda|vda|g' $WORK_ISO_BUILD_DIR/build_iso/new_iso/preseed/auto.seed
fi

sudo sed -i -r 's/timeout\s+[0-9]+/timeout 1/g' $WORK_ISO_BUILD_DIR/build_iso/new_iso/isolinux/isolinux.cfg

seed_md5=`md5sum $WORK_ISO_BUILD_DIR/build_iso/new_iso/preseed/auto.seed | awk '{print $1}'`

sudo sed -i "/label install/ilabel autoinstall\n\
  menu label ^Autoinstall Ubuntu Server\n\
  kernel /install/vmlinuz\n\
  append file=/cdrom/preseed/ubuntu-server.seed vga=788 initrd=/install/initrd.gz auto=true priority=high preseed/file=/cdrom/preseed/auto.seed preseed/file/checksum=$seed_md5 --" $WORK_ISO_BUILD_DIR/build_iso/new_iso/isolinux/txt.cfg

pushd $WORK_ISO_BUILD_DIR/build_iso/new_iso
sudo mkisofs -D -r -V "AUTO_UBUNTU" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $WORK_ISO_BUILD_DIR/output/ubuntu-$OS_VERSION-server-amd64-unattended.iso .
popd
umount $WORK_ISO_BUILD_DIR/build_iso/org_iso
