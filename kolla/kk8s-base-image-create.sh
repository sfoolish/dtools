#!/bin/bash

scp docker_images.txt kk8s-ci-gate-on-line.sh kmm0:~/

ssh -tt kmm0 CREATE_BASE_IMG="base" ~/kk8s-ci-gate-on-line.sh

