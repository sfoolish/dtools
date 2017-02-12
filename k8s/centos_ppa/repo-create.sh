#!/bin/bash

OPV=k8s

rm -rf /centos7-$OPV-ppa
rm -rf /centos7-$OPV-ppa.tar.gz

#make repo
mkdir -p /centos7-$OPV-ppa/{Packages,repodata}

find /var/cache/yum/ -name "*.rpm" | xargs -i cp {} /centos7-$OPV-ppa/Packages/

# rm /centos7-$OPV-ppa/Packages/selinux-policy* -f
# rm /centos7-$OPV-ppa/Packages/systemd* -f

cp /comps.xml /centos7-$OPV-ppa/
cp /ceph_key_release.asc /centos7-$OPV-ppa/
createrepo -g comps.xml /centos7-$OPV-ppa
mkdir /centos7-$OPV-ppa/noarch
mkdir /centos7-$OPV-ppa/noarch/Packages
cp -r /centos7-$OPV-ppa/Packages/ceph* /centos7-$OPV-ppa/noarch/Packages/
cp -r /centos7-$OPV-ppa/repodata/ /centos7-$OPV-ppa/noarch/
tar -zcvf /centos7-$OPV-ppa.tar.gz /centos7-$OPV-ppa


