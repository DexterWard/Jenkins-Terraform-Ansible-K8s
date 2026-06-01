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
    profile = var.profile
    access_key = var.access_key
    secret_key = var.secret_key
}

resource "aws_instance" "kubeadm_master" {
    ami = var.ami
    instance_type = var.instance_type
}