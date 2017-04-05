#!/bin/bash

cat << EOF > sources.list
deb [ arch=amd64 ] http://192.168.137.222/ubuntu/  xenial main restricted universe multiverse
deb [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-security main restricted universe multiverse
deb [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-updates main restricted universe multiverse

deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial main restricted universe multiverse
deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-security main restricted universe multiverse
deb-src [ arch=amd64 ] http://192.168.137.222/ubuntu/ xenial-updates main restricted universe multiverse
EOF

scp sources.list db0:/etc/apt/
scp sources.list db1:/etc/apt/
scp sources.list db2:/etc/apt/

ssh db0 "apt-get update && apt-get install -y python2.7"
ssh db1 "apt-get update && apt-get install -y python2.7"
ssh db2 "apt-get update && apt-get install -y python2.7"

ssh db0 "ln -s python2.7 /usr/bin/python"
ssh db1 "ln -s python2.7 /usr/bin/python"
ssh db2 "ln -s python2.7 /usr/bin/python"

ssh db0 apt-get install software-properties-common
ssh db0 apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
ssh db0 "add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirrors.tuna.tsinghua.edu.cn/mariadb/repo/10.0/ubuntu xenial main'"

ssh db1 apt-get install software-properties-common
ssh db1 apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
ssh db1 "add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirrors.tuna.tsinghua.edu.cn/mariadb/repo/10.0/ubuntu xenial main'"


ssh db2 apt-get install software-properties-common
ssh db2 apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
ssh db2 "add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirrors.tuna.tsinghua.edu.cn/mariadb/repo/10.0/ubuntu xenial main'"

ansible -i inventory -m ping all

