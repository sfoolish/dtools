##############################################################################
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

FROM ubuntu:xenial
MAINTAINER Qi Liang <sfoolish.liang@gmail.com>

LABEL image=sfoolish/dev-daily

ENV HOME_DIR /home/sfoolish

RUN echo 'deb [ arch=amd64 ] http://192.168.137.222/ubuntu/  xenial main restricted universe multiverse \n\
deb [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-security main restricted universe multiverse \n\
deb [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-updates main restricted universe multiverse \n\
 \n\
deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial main restricted universe multiverse \n\
deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-security main restricted universe multiverse \n\
deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-updates main restricted universe multiverse\n' \
    > /etc/apt/sources.list && apt-get update && apt-get install -y \
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

RUN apt-get -y autoremove && \
    apt-get clean

RUN mkdir -p ${HOME_DIR}

RUN git config --global http.sslVerify false

