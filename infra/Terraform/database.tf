resource "aws_db_instance" "url_shortener_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "urlshortenerdb"
  username               = "URLShortener"
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.url_shortener_db_subnet_group.name
  skip_final_snapshot    = true

  tags = {
    Name = "URL Shortener Database"
  }
}

resource "aws_db_subnet_group" "url_shortener_db_subnet_group" {
  name       = "url-shortener-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_1.id, aws_subnet.private_db_2.id]

  tags = {
    Name = "URL Shortener DB Subnet Group"
  }
}
