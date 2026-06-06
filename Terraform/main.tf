terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = ">= 6.0"
      }
    }
}

provider "aws" {
    region = var.region
    access_key = var.access_key
    secret_key = var.secret_key
}

locals {
  ec2-name =  ["master","worker"]
  last-digit = ["0","1"]
}

resource "aws_instance" "kubeadm" {
    ami = var.ami
    instance_type = var.instance_type
    subnet_id = "subnet-06c46458612776034"
    count = 2
    private_ip = "172.31.45.24${local.last-digit[count.index]}"
    key_name = "Jenkins-Terraform-Ansible-K8s"
    

    tags = {
      Name = "kubeadm-${local.ec2-name[count.index]}"
    }

    user_data = <<-EOF
              #!/bin/bash
              sudo hostnamectl set-hostname jenkins-agent
              sudo timedatectl set-timezone Europe/Amsterdam
              sudo apt update
              sudo apt install -y python3 pipx
              pipx install --include-deps ansible
              pipx ensurepath
              cat Ansible/hosts.ini > /home/ubuntu/hosts.ini

              cat <<EOF > hosts.ini
                [master]
                172.31.45.240 ansible_python_interpreter='python3'

                [node]
                172.31.45.241 ansible_python_interpreter='python3'

                [kube-cluster:children]
                master
                node

              EOF
              EOF

 /*   connection {
    type = "ssh"
    user = "ubuntu"
    host = self.public_ip
    private_key = var.ssh-key
  //  private_key = file("../Jenkins-Terraform-Ansible-K8s.pem")
  }

  provisioner "remote-exec" {
    inline = [ 
        "sudo hostnamectl set-hostname jenkins-agent",
        "sudo timedatectl set-timezone Europe/Amsterdam",
        "sudo apt update",
        "sudo apt install -y python3 pipx",
        "pipx install --include-deps ansible",
        "pipx ensurepath",
     ]
  }*/
/*
  provisioner "file" {
    source      = "Ansible/hosts.ini"
    destination = "/home/ubuntu/hosts.ini"
  }*/
}