#!/bin/bash
##############################################################################
# Copyright (c) 2015 Huawei Technologies Co.,Ltd and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -x

SCRIPT_DIR=`cd ${BASH_SOURCE[0]%/*};pwd`
WORK_DIR=${SCRIPT_DIR}/work
ssh_args="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa"
pushd $SCRIPT_DIR

source ./env_config.sh
source ./util.sh
mkdir -p $WORK_DIR
host_vm_dir=$WORK_DIR/vm

download_iso
setup_nat_net mgmt-net $MGMT_NET_GW $MGMT_NET_MASK $MGMT_NET_IP_START $MGMT_NET_IP_END
launch_host_vms
set_all_root_auth
clear_all_seed_cdrom_for_vm

set +x
popd
