terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_security_group" "k8s" {
  name = "k8s-sg"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_my_ip" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4         = "88.203.36.145/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ansible" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4         = "172.31.32.0/20"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "ansible_ping" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4         = "172.31.32.0/20"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "k8s_api" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4         = "172.31.32.2/32"
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "k8s_kubelet" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4         = "172.31.32.2/32"
  ip_protocol       = "tcp"
  from_port         = 10250
  to_port           = 10250
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.k8s.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}


locals {
  ec2-name   = ["master", "node"]
  last-digit = ["1", "2"]
}

resource "aws_instance" "kubeadm" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = "subnet-06c46458612776034"
  vpc_security_group_ids = [aws_security_group.k8s.id]
  count                  = 2
  private_ip             = "172.31.1.${local.last-digit[count.index]}"
  key_name               = "Jenkins-Terraform-Ansible-K8s"


  tags = {
    Name = "kubeadm-${local.ec2-name[count.index]}"
  }

  user_data = templatefile("${path.module}/userdata.sh", {
    ansible_pubkey = file("${path.module}/ansible.pub")
  })


  /*   connection {
    type = "ssh"
    user = "ubuntu"
    host = self.private_ip
  //  private_key = var.ssh-key
    private_key = file("/home/jenkins/workspace/Project1/Jenkins-Terraform-Ansible-K8s.pem")
  }

  provisioner "file" {
    source      = "/home/ubuntu/ansible.pub"
    destination = "/home/ubuntu/"
  }

  provisioner "remote-exec" {
    inline = [ 
        "sudo mv /home/ubuntu/ansible.pub /home/ansible/.ssh/",
        "sudo chown ansible:ansible /home/ansible/.ssh/ansible.pub",
        "sudo cat /home/ansible/.ssh/ansible.pub >> /home/ansible/.ssh/authorized_keys",
     ]
  }*/
}