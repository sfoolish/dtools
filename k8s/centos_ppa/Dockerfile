FROM centos:7.2.1511
MAINTAINER QiLiang

# set cache enable
RUN sed -i 's/keepcache=0/keepcache=1/g' /etc/yum.conf

ADD ./comps.xml /
ADD ./ceph_key_release.asc /
ADD ./repo-create.sh /

RUN yum install createrepo tar yum-plugin-priorities yum-utils -y

