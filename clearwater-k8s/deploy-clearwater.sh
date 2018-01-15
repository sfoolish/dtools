#!/bin/bash

MASTER="vm0"
WORKER="vm1 vm2"
ALL="$MASTER $WORKER"

for i in $ALL; do
    scp -r clearwater_setup $i:~/
done

for i in $ALL; do
    ssh $i ~/clearwater_setup/host_setup.sh
done

ssh $MASTER ~/clearwater_setup/master_setup.sh

for i in $WORKER; do
    ssh $MASTER ~/clearwater_setup/worker_setup.sh
done

ssh $MASTER ~/clearwater_setup/clearwater_setup.sh

