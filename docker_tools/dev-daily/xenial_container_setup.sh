#!/bin/bash

# TODO: Use Dockerfile instead of shell
# docker run -it ubuntu:16.04 bash

function configure_163_mirrors() {
    cat << EOF > /etc/apt/sources.list
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.

deb http://mirrors.163.com/ubuntu/ xenial main restricted
deb-src http://mirrors.163.com/ubuntu/ xenial main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://mirrors.163.com/ubuntu/ xenial-updates main restricted
deb-src http://mirrors.163.com/ubuntu/ xenial-updates main restricted

## Uncomment the following two lines to add software from the 'universe'
## repository.
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://mirrors.163.com/ubuntu/ xenial universe
deb-src http://mirrors.163.com/ubuntu/ xenial universe
deb http://mirrors.163.com/ubuntu/ xenial-updates universe
deb-src http://mirrors.163.com/ubuntu/ xenial-updates universe

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
# deb http://mirrors.163.com/ubuntu/ xenial-backports main restricted
# deb-src http://mirrors.163.com/ubuntu/ xenial-backports main restricted

deb http://mirrors.163.com/ubuntu/ xenial-security main restricted
deb-src http://mirrors.163.com/ubuntu/ xenial-security main restricted
deb http://mirrors.163.com/ubuntu/ xenial-security universe
deb-src http://mirrors.163.com/ubuntu/ xenial-security universe
# deb http://mirrors.163.com/ubuntu/ xenial-security multiverse
# deb-src http://mirrors.163.com/ubuntu/ xenial-security multiverse
EOF
}

function configure_tf_mirrors() {
    cat << EOF > /etc/apt/sources.list
deb [ arch=amd64 ] http://192.168.137.222/ubuntu/  xenial main restricted universe multiverse
deb [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-security main restricted universe multiverse
deb [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-updates main restricted universe multiverse

deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial main restricted universe multiverse
deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-security main restricted universe multiverse
deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-updates main restricted universe multiverse
EOF
}

configure_tf_mirrors
apt-get update && apt-get install -y \
    aptitude \
    autoconf \
    build-essential \
    glibc-doc \
    git \
    golang \
    libtool \
    man \
    manpages \
    manpages-de \
    manpages-de-dev \
    manpages-dev \
    net-tools \
    pkg-config \
    python \
    vim

