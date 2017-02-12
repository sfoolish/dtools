#!/bin/bash

ssh km0 sed -i 's/keepcache=0/keepcache=1/g' /etc/yum.conf
scp ./comps.xml km0:/
scp ./ceph_key_release.asc km0:/
scp ./repo-create.sh km0:/
ssh km0 yum install createrepo tar yum-plugin-priorities yum-utils -y

