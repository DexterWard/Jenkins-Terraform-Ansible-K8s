resource "aws_db_instance" "db1" {
  db_name                = "k8s"
  identifier             = "k8s"
  instance_class         = "db.t4g.micro"
  allocated_storage      = "20"
  engine                 = "postgres"
  username               = "postgres"
  skip_final_snapshot    = true
  publicly_accessible    = true
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.db.id]
  depends_on             = [aws_security_group.db]
}

output "vpc_id" {
  value = element(tolist(aws_db_instance.db1.vpc_security_group_ids), 0)
  //value = aws_db_instance.db1.vpc_security_group_ids
}