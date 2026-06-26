resource "aws_vpc" "main" {
  cidr_block       = "172.31.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "pipeline"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = "true"

  tags = {
    "Name"                             = "Public subnet A"
    "kubernetes.io/cluster/kubernetes" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.2.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = "true"

  tags = {
    "Name"                             = "Public subnet B"
    "kubernetes.io/cluster/kubernetes" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}