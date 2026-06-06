#!/bin/bash

#Set hostname and time and date
sudo hostnamectl set-hostname jenkins-agent
timedatectl set-timezone Europe/Amsterdam

#Install dependencies
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common openjdk-21-jdk

#Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

apt update
apt install -y terraform

#Install Python
apt install -y python3 pipx 

#Install Ansible
pipx install --include-deps ansible
pipx install ansible-core


#Create the Jenkins user
useradd -m -s /bin/bash jenkins
su -u jenkins -c "pipx ensurepath"

