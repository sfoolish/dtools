##############################################################################
# Copyright (c) 2015 Huawei Technologies Co.,Ltd and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# this is a modified copy of bottlenecks/utils/rubbos_dev_env_setup/env_config.sh

export HOSTNAMES=${HOSTNAMES:-"ubuntu"}
export VIRT_NUMBER=${VIRT_NUMBER:-"1"}
export VIRT_MEM=${VIRT_MEM:-"4096"}
export VIRT_CPUS=${VIRT_CPUS:-"4"}
export IMAGE_URL=${IMAGE_URL:-"https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img"}
export IMAGE_NAME=${IMAGE_NAME:-"disk.img"}
export IPADDR_PREFIX=${IPADDR_PREFIX:-"192.168.122."}

