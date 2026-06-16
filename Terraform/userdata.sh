#!/bin/bash

timedatectl set-timezone Europe/Amsterdam              

apt update
apt install -y python3

useradd -m -s /bin/bash ansible
mkdir -p /home/ansible/.ssh

cat <<EOF >/home/ansible/.ssh/authorized_keys
${ansible_pubkey}
EOF

chown -R ansible:ansible /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys

echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible