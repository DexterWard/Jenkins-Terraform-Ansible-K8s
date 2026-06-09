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

resource "aws_security_group" "k8s" {
  name        = "k8s-sg"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4   = "88.203.36.145/32"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

locals {
  ec2-name =  ["master","node"]
  last-digit = ["0","1"]
}

resource "aws_instance" "kubeadm" {
    ami = var.ami
    instance_type = var.instance_type
    subnet_id = "subnet-06c46458612776034"
    vpc_security_group_ids = [aws_security_group.k8s.id]
    count = 2
    private_ip = "172.31.1.${local.last-digit[count.index]}"
    key_name = "Jenkins-Terraform-Ansible-K8s"
    

    tags = {
      Name = "kubeadm-${local.ec2-name[count.index]}"
    }

    user_data = <<-EOF
              #!/bin/bash
              sudo hostnamectl set-hostname kubeadm-${local.ec2-name[count.index]};
              sudo timedatectl set-timezone Europe/Amsterdam;
              sudo apt update;
              sudo apt install -y python3
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