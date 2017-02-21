##############################################################################
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

FROM centos:7.3.1611
MAINTAINER Qi Liang <sfoolish.liang@gmail.com>

LABEL image=sfoolish/dev-daily

ENV HOME_DIR /home/sfoolish

RUN rm -rf /etc/yum.repos.d/*
COPY mirrors.repo /etc/yum.repos.d
RUN yum update -y && yum install -y \
    curl \
    dos2unix \
    git \
    git-review \
    golang \
    ipython \
    python \
    sshpass \
    tree \
    vim \
    wget

RUN mkdir -p ${HOME_DIR}

RUN git config --global http.sslVerify false

