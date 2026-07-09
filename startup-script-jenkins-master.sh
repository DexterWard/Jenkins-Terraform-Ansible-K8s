#!/bin/bash

#Set hostname and time and date
sudo hostnamectl set-hostname jenkins-master
timedatectl set-timezone Europe/Amsterdam

#Install Docker
apt update
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh

systemctl start docker
systemctl enable docker

#Add groups, users and ownership
groupadd docker
useradd -m -s /bin/bash jenkins
usermod -aG docker jenkins
su - jenkins -c "newgrp docker"
su - jenkins -c "docker volume create my-data"

#Create ssh keys to connect with agents
su - jenkins -c "mkdir /home/jenkins/.ssh"
mkdir -p /var/jenkins_home/.ssh
touch /var/jenkins_home/.ssh/known_hosts
chown -R jenkins:jenkins /var/jenkins_home
chmod 600 /var/jenkins_home/.ssh/known_hosts

su - jenkins -c "ssh-keygen -t ed25519 -N '' -f /home/jenkins/.ssh/jenkins-agent"

#Start the jenkins container
su - jenkins -c "docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -v my-data:/var/jenkins_home \
  -p 8080:8080 \
  -e TZ=Europe/Amsterdam \
  jenkins/jenkins:lts"
