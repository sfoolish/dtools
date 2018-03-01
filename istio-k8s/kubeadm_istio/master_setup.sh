#!/bin/bash

set -ex

sudo kubeadm init --apiserver-advertise-address=192.168.122.195  --service-cidr=10.96.0.0/16 --pod-network-cidr=10.32.0.0/12 --token 8c5adc.1cec8dbf339093f0
mkdir ~/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f http://git.io/weave-kube-1.6

# Enable mutating webhook admission controller
# https://istio.io/docs/setup/kubernetes/sidecar-injection.html
export ADMISSION_CONTROL="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,NodeRestriction,ResourceQuota"
export KUBE_APISERVER_CONF="/etc/kubernetes/manifests/kube-apiserver.yaml"
sed -i "s/admission-control=.*/admission-control=$ADMISSION_CONTROL/g" $KUBE_APISERVER_CONF

set +e
# wait for kube-apiserver restart
r="1"
while [ $r -ne "0" ]
do
   sleep 1
   kubectl get pods > /dev/null
   r=$?
done
set -e

# check if admissionregistration.k8s.io/v1beta1 API is enabled
kubectl api-versions | grep admissionregistration

