#!/bin/bash

set -ex
DIR="$(dirname `readlink -f $0`)"

cd $DIR
./istio/deploy.sh
./istio/bookinfo.sh
./istio/clean_bookinfo.sh

