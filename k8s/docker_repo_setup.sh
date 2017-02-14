#!/bin/bash

# install docker
curl -sSL https://get.docker.io | bash

# configure docker daemon
mkdir -p /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/docker.conf <<-'EOF'
[Service]
MountFlags=shared
EOF
systemctl daemon-reload
systemctl restart docker

# configure docker registry
docker run -d -p 4000:5000 --restart=always --name registry registry:2

# pull docker images
cat docker_images.txt | while read image; do
    docker pull $image
done

# push docker images to local registry
docker images | grep -v TAG | grep -v local | awk '{print $1,$2}' | while read -r image tag; do
    docker tag ${image}:${tag} localhost:4000/${image}:${tag}
    docker push localhost:4000/${image}:${tag}
done

