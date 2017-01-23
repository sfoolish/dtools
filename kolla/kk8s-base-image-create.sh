#!/bin/bash

scp docker_images_kmm.txt kk8s-ci-gate-on-line.sh kmm0:~/docker_images.txt
ssh -tt kmm0 CREATE_BASE_IMG="base" ~/kk8s-ci-gate-on-line.sh

for kmn in kmn1 kmn2
do
    scp docker_images_kmn.txt kk8s-ci-gate-on-line.sh $kmn:~/docker_images.txt
    ssh -tt $kmn CREATE_BASE_IMG="base" ~/kk8s-ci-gate-on-line.sh
done

