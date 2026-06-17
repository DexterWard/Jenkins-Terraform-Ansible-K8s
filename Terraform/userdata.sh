#!/bin/bash

#Set timezone
timedatectl set-timezone Europe/Amsterdam              

#Install python
apt update
apt install -y python3

#Create ansible user
useradd -m -s /bin/bash ansible
mkdir -p /home/ansible/.ssh

#Add ssh keys
cat <<EOF >/home/ansible/.ssh/authorized_keys
${ansible_pubkey}
EOF

chown -R ansible:ansible /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys

echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible

#Change swappiness
echo "vm.swappiness=70" > /etc/sysctl.d/99-custom.conf
sysctl --system

#Setup containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

#Kernel parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

#Configuring repo and installation
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
apt-cache madison kubeadm
apt-get install -y kubelet=1.32.0-1.1 kubeadm=1.32.0-1.1 kubectl=1.32.0-1.1 cri-tools=1.32.0-1.1
sudo apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet