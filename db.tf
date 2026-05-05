resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "application_db"
  subnet_ids = aws_subnet.isolated_rds[*].id

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage         = 50
  storage_type              = "gp3" 
  db_name                   = "web_db"
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = "db.t3.micro"
  username                  = var.credentials_username_password.username
  password                  = var.credentials_username_password.password
  parameter_group_name      = "default.mysql8.0"
  skip_final_snapshot       = true
  vpc_security_group_ids    = [aws_security_group.db_sg.id]
  multi_az                  = true 
  db_subnet_group_name      = aws_db_subnet_group.rds_subnet_group.name 
}