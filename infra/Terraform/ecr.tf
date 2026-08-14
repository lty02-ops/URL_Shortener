resource "aws_ecr_repository" "backend" {
  name                 = "url-shortener-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "URL Shortener Backend"
  }
}