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
  cidr_ipv4         = "172.31.0.0/20"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "ansible_ping" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4         = "172.31.0.0/20"
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_ingress_rule" "k8s_api" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4         = "172.31.0.0/20"
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "k8s_kubelet" {
  security_group_id = aws_security_group.k8s.id
  cidr_ipv4         = "172.31.0.0/20"
  ip_protocol       = "tcp"
  from_port         = 10250
  to_port           = 10250
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.k8s.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "db" {
  name = "db-sg"
}

resource "aws_vpc_security_group_ingress_rule" "postgre_connection" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "172.31.0.0/20"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}