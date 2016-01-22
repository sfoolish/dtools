##############################################################################
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

FROM ubuntu:14.04
MAINTAINER Qi Liang <sfoolish.liang@gmail.com>

LABEL image=sfoolish/dev-daily

ENV HOME_DIR /home/sfoolish

RUN apt-get update && apt-get install -y \
    curl \
    dos2unix \
    git \
    git-review \
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

