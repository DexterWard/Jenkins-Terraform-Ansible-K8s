resource "aws_db_instance" "db1" {
  db_name                = "k8s"
  identifier             = "k8s"
  instance_class         = "db.t4g.micro"
  allocated_storage      = "20"
  engine                 = "postgres"
  username               = "postgres"
  skip_final_snapshot    = true
  publicly_accessible    = false
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.db.id]
  depends_on             = [aws_security_group.db]
  db_subnet_group_name   = aws_db_subnet_group.db.name
}

data "aws_db_instance" "database" {
  db_instance_identifier = "k8s"
  depends_on             = [aws_db_instance.db1]
}

output "database_address" {
  value = data.aws_db_instance.database.address
}