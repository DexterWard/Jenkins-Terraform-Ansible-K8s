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
}

resource "aws_instance" "kubeadm" {
    ami = var.ami
    instance_type = var.instance_type
    subnet_id = "subnet-06c46458612776034"
    private_ip = "172.31.45.24${tostring([count.index])}"
    count = 2

    tags = {
      Name = "kubeadm-${local.ec2-name[count.index]}"
    }

    connection {
    type = "ssh"
    user = "ubuntu"
    host = self.public_ip
    private_key = file("../Jenkins-Terraform-Ansible-K8s.pem")
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
  }

  provisioner "file" {
    source      = "Ansible/hosts.ini"
    destination = "/home/ubuntu/hosts.ini"
  }
}