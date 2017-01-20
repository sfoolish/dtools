#!/bin/bash

scp docker_images.txt kk8s-ci-gate-on-line.sh kmaster:~/

ssh -tt kmaster CREATE_BASE_IMG="base" ~/kk8s-ci-gate-on-line.sh

