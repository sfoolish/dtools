#!/bin/bash
set -x

pushd ../
git apply kolla/kk8s-libvirt-env.diff
popd

# DATE=$(date +"%y-%m-%d-%T")
DATE=$(date +"%y-%m-%d-%H")
LOG_DIR=/tmp/k8s-ci-${DATE}

mkdir -p ${LOG_DIR}

# deploy vms
pushd ../libvirt_tools

i=0
while [ $i -lt 10 ]; do
  ./deploy.sh 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a ${LOG_DIR}/libvirt_deploy.log
  sleep 10
  ssh kmm0 "hostname"
  if [ $? == 0 ]; then
    echo "Depoloy success!" >> ${LOG_DIR}/libvirt_deploy.log
    break
  fi
  
  # try restart vm
  virsh destroy kmm0
  sleep 1
  virsh start kmm0
  sleep 10
  ssh kmm0 "hostname"
  if [ $? == 0 ]; then
    echo "Depoloy success after restart!" >> ${LOG_DIR}/libvirt_deploy.log
    break
  fi
  echo "!!! Deploy $(i+1) Times Failed !!!" >> ${LOG_DIR}/libvirt_deploy.log
done

popd

ssh kmm0 "hostname"
if [ $? != 0 ]; then
  echo "!!! Deploy Failed EXIT !!!" >> ${LOG_DIR}/libvirt_deploy.log
  exit 1
fi

git checkout ../

