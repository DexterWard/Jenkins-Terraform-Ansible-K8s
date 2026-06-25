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
  iam_instance_profile   = aws_iam_instance_profile.kubeadm_profile.name
  source_dest_check      = false

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "kubeadm-${local.ec2-name[count.index]}"
  }

  user_data = templatefile("${path.module}/userdata.sh", {
    ansible_pubkey = file("${path.module}/ansible.pub")
  })

  user_data_replace_on_change = true



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

resource "aws_ecr_repository" "ecr" {
  name                 = "my-project"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_vpc" "default" {
  default = true
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}