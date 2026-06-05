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

resource "aws_instance" "kubeadm_master" {
    ami = var.ami
    instance_type = var.instance_type
    count = 2

    tags = {
      Name = "kubeadm-${local.ec2-name[count.index]}"
    }
}