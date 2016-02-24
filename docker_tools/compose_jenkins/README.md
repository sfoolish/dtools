## Use docker compose to build jenkins distributed builds

### docker-compose install

```sh

$ curl -L https://github.com/docker/compose/releases/download/1.6.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose

```

Refer https://docs.docker.com/compose/install/ for more docker-compose install methods.

Refer https://docs.docker.com/compose/gettingstarted/ for basic compose usage.

### start jenkins dockers

```sh

$ docker-compose up

```

### jenkins slave node configuration

Use jenkins web ui to configure jenkins slave nodes

http://master:8880/computer/new create new node
set executors number, remote workspace, Launch methods to Launch slave agent via Java Web Start

### REF

* https://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds
* https://iww.inria.fr/tech-zone/using-docker-to-run-jenkins-jobs/

