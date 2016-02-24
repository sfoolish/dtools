#!/bin/bash

cd /home/jenkins

# wait until jenkins master is ready
while true
do
    wget http://master:8080/jnlpJars/slave.jar
    if [ $? = 0 ]; then
        break
    fi
    sleep 1
done

java -jar slave.jar -jnlpUrl http://master:8080/computer/slave1/slave-agent.jnlp

