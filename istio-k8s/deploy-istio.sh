#!/bin/bash

MASTER="vm0"
WORKER="vm1 vm2"
ALL="$MASTER $WORKER"

for i in $ALL; do
    scp -r kubeadm_istio $i:~/
done

for i in $ALL; do
    ssh $i ~/kubeadm_istio/host_setup.sh
done

ssh $MASTER ~/kubeadm_istio/master_setup.sh

for i in $WORKER; do
    ssh $i ~/kubeadm_istio/worker_setup.sh
done

ssh $MASTER ~/kubeadm_istio/deploy.sh

