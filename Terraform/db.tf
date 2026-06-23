resource "aws_db_instance" "db1" {
  db_name              = "k8s"
  instance_class       = "db.t4g.micro"
  allocated_storage    = "20"
  engine               = "postgresql"
  username             = "postgres"
  skip_final_snapshot  = true
  publicly_accessible  = true
  password             = var.db_password
}