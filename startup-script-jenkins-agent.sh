#!/bin/bash

#Set hostname and time and date
hostnamectl set-hostname jenkins-agent
timedatectl set-timezone Europe/Amsterdam

#Install dependencies
apt-get update && apt-get install -y gnupg software-properties-common openjdk-21-jdk unzip

#Install Docker to build images
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh

#Add groups, users and ownership
groupadd docker
useradd -m -s /bin/bash jenkins
usermod -aG docker jenkins

su -u jenkins -c "mkdir -p /home/jenkins/.ssh"
su -u jenkins -c "touch /home/jenkins/.ssh/authorized_keys"
chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
chmod 700 /home/jenkins/.ssh
chmod 600 /home/jenkins/.ssh/authorized_keys

#Install aws cli
apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

#Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

apt update
apt install -y terraform

#Install Python
apt install -y python3 pipx

#Create the Ansible user
useradd -m -s /bin/bash ansible

#Install Ansible
#su - ansible -c "pipx install --include-deps ansible"
#su - ansible -c "pipx install ansible-core"

su - jenkins -c "pipx install ansible ansible-core"
su - jenkins -c "pipx ensurepath"

#Allow ssh connections between nodes
sed -i s/#PubkeyAuthentication/PubkeyAuthentication/g /etc/ssh/sshd_config
sed -i s/#AuthorizedKeysFile/AuthorizedKeysFile/g /etc/ssh/sshd_config
systemctl restart sshd

mkdir /home/jenkins/.ssh
touch /home/jenkins/.ssh/authorized_keys

#Increase /tmp
mount -o remount,size=4G /tmp