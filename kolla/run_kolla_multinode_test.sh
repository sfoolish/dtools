#!/bin/bash

date

cd ../libvirt_tools/
./deploy.sh
cd -

date

ansible -i inventory all -m copy -a "src=/root/.ssh/id_rsa dest=/root/.ssh/id_rsa mode=600"
ansible -i inventory all -m copy -a "src=/root/.ssh/id_rsa.pub dest=/root/.ssh/id_rsa.pub mode=644"
ansible -i inventory all -m shell -a 'ifconfig eth1 up'

date

ansible -i inventory ansible -m copy -a "src=kolla-multinode1.sh dest=~/kolla-multinode1.sh mode=777"
ansible -i inventory ansible -m shell -a '~/kolla-multinode1.sh'

date

ansible -i inventory kolla -m copy -a "src=kolla-multinode2.sh dest=~/kolla-multinode2.sh mode=777"
ansible -i inventory kolla -m shell -a '~/kolla-multinode2.sh'

date

ansible -i inventory ansible -m shell -a "ANSIBLE_HOST_KEY_CHECKING=False kolla-ansible prechecks -i /usr/share/kolla/ansible/inventory/multinode"

date

ansible -i inventory ansible -m shell -a "ANSIBLE_HOST_KEY_CHECKING=False kolla-ansible deploy -i /usr/share/kolla/ansible/inventory/multinode"

date

ansible -i inventory ansible -m copy -a "src=kolla-init-runonce.sh dest=~/kolla-init-runonce.sh mode=777"
ansible -i inventory ansible -m shell -a '~/kolla-init-runonce.sh'

date

ansible -i inventory ansible -m copy -a "src=kolla-boot-vm.sh dest=~/kolla-boot-vm.sh mode=777"
ansible -i inventory ansible -m shell -a '~/kolla-boot-vm.sh'

date

