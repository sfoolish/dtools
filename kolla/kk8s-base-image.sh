#!/bin/bash

scp docker_images.txt kk8s-ci-gate-on-line.sh kmaster:~/
export CREATE_BASE_IMG="base"
ssh -t kmaster ~/kk8s-ci-gate-on-line.sh
