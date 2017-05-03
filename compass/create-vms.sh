#!/bin/bash
set -x

source libvirt-env-trusty

# DATE=$(date +"%y-%m-%d-%T")
DATE=$(date +"%y-%m-%d-%H")
LOG_DIR=/tmp/k8s-ci-${DATE}

mkdir -p ${LOG_DIR}

# deploy vms
pushd ../libvirt_tools
./deploy.sh 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a ${LOG_DIR}/libvirt_deploy.log
popd

ssh $KMASTER "hostname"
if [ $? != 0 ]; then
  echo "!!! Deploy Failed EXIT !!!" >> ${LOG_DIR}/libvirt_deploy.log
  exit 1
fi

