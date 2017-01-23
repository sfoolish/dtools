#!/bin/bash

HOST_NAME=kmm0 IMAGE_NAME=disk.img_image-pulled-kmm0 ./_kk8s-base-image-boot.sh
HOST_NAME=kmn1 IMAGE_NAME=disk.img_image-pulled-kmn1 ./_kk8s-base-image-boot.sh
HOST_NAME=kmn2 IMAGE_NAME=disk.img_image-pulled-kmn2 ./_kk8s-base-image-boot.sh

