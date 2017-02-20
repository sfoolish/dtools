# Kargo deploy

## Create vms for kargo deploy

Below commands will create vms: kargo0, kargo1, kargo2, kargo3, kargo4,
with ip addr rang from 192.168.122.121 to 192.168.122.125.

```bash
git clone https://github.com/sfoolish/dtools
cd dtools/
git checkout centos
cd kargo
./create-vms.sh
```

## Centos ansible setup

```bash
yum install epel-release
yum groupinstall 'Development Tools'
yum install -y python-devel python-pip libffi-devel openssl-devel

# install ansible to the system
yum install -y python-netaddr
yum install -y ansible

# install ansible in a python virtualenv
yum install -y python-virtualenv
virtualenv .venv
source .venv/bin/python
pip install netaddr
pip install ansible
```

## kargo deploy

```bash
git clone https://github.com/kubernetes-incubator/kargo
cd kargo

cp -r inventory my_inventory
cat << "EOF" > my_inventory/inventory.cfg
[all]
## Configure 'ip' variable to bind kubernetes services on a
## different ip than the default iface
node1 ansible_ssh_host=192.168.122.121  # ip=10.3.0.1
node2 ansible_ssh_host=192.168.122.122  # ip=10.3.0.2
node3 ansible_ssh_host=192.168.122.123  # ip=10.3.0.3
node4 ansible_ssh_host=192.168.122.124  # ip=10.3.0.4
#node5 ansible_ssh_host=192.168.122.125  # ip=10.3.0.5

## configure a bastion host if your nodes are not directly reachable
bastion ansible_ssh_host=192.168.122.125  ansible_ssh_user=root

[kube-master]
node1
node2

[etcd]
node1
node2
node3

[kube-node]
node2
node3
node4
#node5

[k8s-cluster:children]
kube-node
kube-master

[calico-rr]

[vault]
EOF

# Do the real deploy
ansible-playbook -i my_inventory/inventory.cfg cluster.yml -b -v
```

Check kubernetes nodes status

```console
[root@21-21 kargo]# ssh kargo1
[root@kargo1 ~]# kubectl get node
NAME      STATUS                     AGE
kargo0    Ready,SchedulingDisabled   10m
kargo1    Ready                      10m
kargo2    Ready                      10m
kargo3    Ready                      10m
```

## Reference links

* https://github.com/kubernetes-incubator/kargo
* https://github.com/kubernetes-incubator/kargo/blob/master/docs/getting-started.md

---

## Appendix

### Kargo deploy issues

cp -r inventory my_inventory
declare -a IPS=(192.168.122.121 192.168.122.122 192.168.122.123 192.168.122.124 192.168.122.125)
CONFIG_FILE=my_inventory/inventory.cfg python3 contrib/inventory_builder/inventory.py ${IPS}

CONFIG_FILE=inventory_test/inventory.cfg python3 contrib/inventory_builder/inventory.py ${IPS}

[all]
node1 	 ansible_host=192.168.122.121 ip=192.168.122.121

[kube-master]
node1

[kube-node]
node1

[etcd]
node1

[k8s-cluster:children]
kube-node
kube-master

[calico-rr]

---

### Kargo deploy Fixed issues

#### python-netaddr not installed on ansible host

TASK [bastion-ssh-config : set_fact] *******************************************
Sunday 19 February 2017  23:43:31 -0800 (0:00:00.020)       0:00:00.044 *******
fatal: [localhost]: FAILED! => {"failed": true, "msg": "The ipaddr filter requires python-netaddr be installed on the ansible cont
roller"}

```bash
apt-get install -y python-netaddr
# or
yum -y install python-netaddr
# or 
pip install netaddr
```

Reference links

* https://github.com/CiscoCloud/kubernetes-ansible/issues/28

#### bastion node ansible_ssh_user not configured

```
TASK [bastion-ssh-config : set_fact] *******************************************
Thursday 16 February 2017  03:28:40 -0800 (0:00:00.033)       0:00:00.093 *****
fatal: [localhost]: FAILED! => {"failed": true, "msg": "the field 'args' has an invalid value, which appears to include a variable that is undefined. The error was: 'ansible_ssh_user' is undefined\n\nThe error appears to have been in '/opt/kk8s/dtools_daily/kargo/kargo/roles/bastion-ssh-config/tasks/main.yml': line 11, column 3, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n# To figure out the real ssh user, we delegate this task to the bastion and store the ansible_ssh_user in real_user\n- set_fact:\n  ^ here\n"}
```

update bastion configure in my_inventory/inventory.cfg

`bastion ansible_ssh_host=192.168.122.125  ansible_ssh_user=root`

#### Ansilbe version issue

Deploy failure Ansible version info

```console
[root@21-21 kargo]# ansible --version
ansible 2.2.0.0
  config file = /opt/kk8s/dtools_daily/kargo/kargo/ansible.cfg
  configured module search path = ['./library']
```

Failed with error

```console
fatal: [node4]: FAILED! => {"changed": false, "failed": true, "msg": "AnsibleError: template error while templating string: expected token '=', got 'end of statement block'. String: # logging to stderr means we get it in the systemd journal\nKUBE_LOGGING=\"--logtostderr=true\"\nKUBE_LOG_LEVEL=\"--v={{ kube_log_level }}\"\n# The address for the info server to serve on (set to 0.0.0.0 or \"\" for all interfaces)\nKUBELET_ADDRESS=\"--address={{ ip | default(\"0.0.0.0\") }}\"\n# The port for the info server to serve on\n# KUBELET_PORT=\"--port=10250\"\n# You may leave this blank to use the actual hostname\nKUBELET_HOSTNAME=\"--hostname-override={{ ansible_hostname }}\"\n\n{# Base kubelet args #}\n{% set kubelet_args_base %}--pod-manifest-path={{ kube_manifest_dir }} \\\n--pod-infra-container-image={{ pod_infra_image_repo }}:{{ pod_infra_image_tag }} \\\n--kube-reserved cpu={{ kubelet_cpu_limit }},memory={{ kubelet_memory_limit|regex_replace('Mi', 'M') }} \\\n--node-status-update-frequency={{ kubelet_status_update_frequency }}{% endset %}\n\n{# DNS settings for kubelet #}\n{% if dns_mode == 'kubedns' %}\n{% set kubelet_args_cluster_dns %}--cluster_dns={{ skydns_server }}{% endset %}\n{% elif dns_mode == 'dnsmasq_kubedns' %}\n{% set kubelet_args_cluster_dns %}--cluster_dns={{ dns_server }}{% endset %}\n{% else %}\n{% set kubelet_args_cluster_dns %}{% endset %}\n{% endif %}\n{% set kubelet_args_dns %}{{ kubelet_args_cluster_dns }} --cluster_domain={{ dns_domain }} --resolv-conf={{ kube_resolv_conf }}{% endset %}\n\n{# Location of the apiserver #}\n{% set kubelet_args_kubeconfig %}--kubeconfig={{ kube_config_dir}}/node-kubeconfig.yaml --require-kubeconfig{% endset %}\n{% if standalone_kubelet|bool %}\n{# We are on a master-only host. Make the master unschedulable in this case. #}\n{% set kubelet_args_kubeconfig %}{{ kubelet_args_kubeconfig }} --register-schedulable=false{% endset %}\n{% endif %}\n\nKUBELET_ARGS=\"{{ kubelet_args_base }} {{ kubelet_args_dns }} {{ kubelet_args_kubeconfig }}\"\n{% if kube_network_plugin is defined and kube_network_plugin in [\"calico\", \"weave\", \"canal\"] %}\nKUBELET_NETWORK_PLUGIN=\"--network-plugin=cni --network-plugin-dir=/etc/cni/net.d\"\n{% elif kube_network_plugin is defined and kube_network_plugin == \"weave\" %}\nDOCKER_SOCKET=\"--docker-endpoint=unix:/var/run/weave/weave.sock\"\n{% elif kube_network_plugin is defined and kube_network_plugin == \"cloud\" %}\n# Please note that --reconcile-cidr is deprecated and a no-op in Kubernetes 1.5 but still required in 1.4\nKUBELET_NETWORK_PLUGIN=\"--hairpin-mode=promiscuous-bridge --network-plugin=kubenet --reconcile-cidr=true\"\n{% endif %}\n# Should this cluster be allowed to run privileged docker containers\nKUBE_ALLOW_PRIV=\"--allow-privileged=true\"\n{% if cloud_provider is defined and cloud_provider in [\"openstack\", \"azure\"] %}\nKUBELET_CLOUDPROVIDER=\"--cloud-provider={{ cloud_provider }} --cloud-config={{ kube_config_dir }}/cloud_config\"\n{% elif cloud_provider is defined and cloud_provider == \"aws\" %}\nKUBELET_CLOUDPROVIDER=\"--cloud-provider={{ cloud_provider }}\"\n{% else %}\nKUBELET_CLOUDPROVIDER=\"\"\n{% endif %}\n"}
```

Deploy success Ansible version info

```console
root@21-20:/opt/dtools_centos# ansible-playbook --version
ansible-playbook 2.2.1.0
  config file = /etc/ansible/ansible.cfg
  configured module search path = Default w/o overrides
```

Test with local ansible code with below patch

```diff
diff --git a/ansible/roles/test/defaults/main.yml b/ansible/roles/test/defaults/main.yml
index fb30074..3612a78 100644
--- a/ansible/roles/test/defaults/main.yml
+++ b/ansible/roles/test/defaults/main.yml
@@ -1,3 +1,5 @@
 ---

 default_env: "hello default env"
+kube_manifest_dir: /tmp
+kubelet_status_update_frequency: 100
diff --git a/ansible/roles/test/tasks/main.yml b/ansible/roles/test/tasks/main.yml
index 674de77..5b6f360 100644
--- a/ansible/roles/test/tasks/main.yml
+++ b/ansible/roles/test/tasks/main.yml
@@ -23,6 +23,9 @@
   debug:
     msg: "{{ template_gen_out.stdout }}"

+- name: Write kubelet config file
+  template: src=kubelet.j2 dest=/kubelet.env backup=yes
+
 - name: rm test files
   file:
     path: "{{ item }}"
diff --git a/ansible/roles/test/templates/kubelet.j2 b/ansible/roles/test/templates/kubelet.j2
new file mode 100644
index 0000000..ee82685
--- /dev/null
+++ b/ansible/roles/test/templates/kubelet.j2
@@ -0,0 +1,3 @@
+{# Base kubelet args #}
+{% set kubelet_args_base %}--pod-manifest-path={{ kube_manifest_dir }} \
+--node-status-update-frequency={{ kubelet_status_update_frequency }}{% endset %}
```

Failure log

```console
[root@21-21 ansible]# ansible-playbook  -i inventory playbook.yml

TASK [test : Write kubelet config file] ****************************************
fatal: [ansilbe0]: FAILED! => {"changed": false, "failed": true, "msg": "AnsibleError: template error while templating
string: expected token '=', got 'end of statement block'. String: {# Base kubelet args #}\n{% set kubelet_args_base %}-
-pod-manifest-path={{ kube_manifest_dir }} \\\n--node-status-update-frequency={{ kubelet_status_update_frequency }}{% e
ndset %}\n"}
fatal: [ansilbe1]: FAILED! => {"changed": false, "failed": true, "msg": "AnsibleError: template error while templating
string: expected token '=', got 'end of statement block'. String: {# Base kubelet args #}\n{% set kubelet_args_base %}-
-pod-manifest-path={{ kube_manifest_dir }} \\\n--node-status-update-frequency={{ kubelet_status_update_frequency }}{% e
ndset %}\n"}
        to retry, use: --limit @/opt/kk8s/dtools_daily/ansible/playbook.retry
```

Success log

```console
(.venv)[root@21-21 ansible]# ansible-playbook  -i inventory playbook.yml

TASK [test : Write kubelet config file] ****************************************
changed: [ansilbe0]
changed: [ansilbe1]
```

