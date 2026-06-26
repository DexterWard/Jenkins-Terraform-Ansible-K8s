resource "aws_vpc" "main" {
  cidr_block       = "172.31.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
  "kubernetes.io/cluster/kubernetes" = "shared"
  "kubernetes.io/role/elb"           = "1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
  "kubernetes.io/cluster/kubernetes" = "shared"
  "kubernetes.io/role/elb"           = "1"
  }
}

output "vpc_id" {
  value = data.aws_vpc.main.id
}