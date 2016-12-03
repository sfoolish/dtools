##############################################################################
# Copyright (c) 2015 Huawei Technologies Co.,Ltd and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# this is a modified copy of bottlenecks/utils/rubbos_dev_env_setup/env_config.sh

export HOSTNAMES=${HOSTNAMES:-"osa,infra1,compute1,storage1"}
export VIRT_NUMBER=${VIRT_NUMBER:-"4"}
#export VIRT_NUMBER=${VIRT_NUMBER:-"1"}
export VIRT_MEM=${VIRT_MEM:-"10240"}
export VIRT_CPUS=${VIRT_CPUS:-"8"}
export IMAGE_URL=${IMAGE_URL:-"https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img"}
export IMAGE_NAME=${IMAGE_NAME:-"disk.img"}
export IPADDR_PREFIX=${IPADDR_PREFIX:-"192.168.122."}

export MGMT_NET_GW="192.168.222.1"
export MGMT_NET_MASK="255.255.255.0"
export MGMT_NET_IP_START="192.168.222.2"
export MGMT_NET_IP_END="192.168.222.254"
