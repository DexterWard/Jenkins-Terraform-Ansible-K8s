#!/bin/bash
apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh

systemctl start docker
systemctl enable docker

groupadd docker
usermod -aG docker ubuntu
su - ubuntu -c "newgrp docker"

su - ubuntu -c "docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -e TZ=Europe/Amsterdam \
  jenkins/jenkins:lts"
