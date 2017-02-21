#!/bin/bash

for dir in centos7 xenial; do
    pushd $dir
    docker build -t sf$dir .
    popd
done

