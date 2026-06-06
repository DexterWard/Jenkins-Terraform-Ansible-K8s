ephemeral "random_password" "db_password" {
  length           = 8
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "db1" {
  db_name              = "k8s"
  instance_class       = "db.t4g.micro"
  allocated_storage    = "20"
  engine               = "mysql"
  username             = "admin"
  skip_final_snapshot  = true
  publicly_accessible  = true
  password_wo          = ephemeral.random_password.db_password.result
  password_wo_version  = 1
}
/*
resource "aws_secretsmanager_secret" "db_password" {
  name = "db_pass"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string_wo = ephemeral.random_password.db_password.result
  secret_string_wo_version = 1
}

ephemeral "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret_version.db_password.secret_id
  
}*/