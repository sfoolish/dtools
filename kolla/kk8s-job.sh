#!/bin/bash
set -x

DATE=$(date +"%y-%m-%d-%H")
LOG_DIR=/tmp/k8s-ci-${DATE}

mkdir -p ${LOG_DIR}

./kk8s-create-vms.sh

scp kk8s-ci-gate-on-line.sh kmaster:~/
ssh -t kmaster ~/kk8s-ci-gate-on-line.sh 2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a ${LOG_DIR}/kk8s-ci.log

