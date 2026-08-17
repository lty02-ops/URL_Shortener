data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

locals {
  ecr_registry = split("/", aws_ecr_repository.backend.repository_url)[0]
}

resource "aws_launch_template" "backend" {
  name_prefix   = "url-shortener-backend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  }

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data = base64encode(templatefile(
    "${path.module}/user_data.sh.tftpl",
    {
      aws_region         = var.region
      ecr_registry       = local.ecr_registry
      ecr_repository_url = aws_ecr_repository.backend.repository_url
      db_host            = aws_db_instance.url_shortener_db.address
      db_name            = aws_db_instance.url_shortener_db.db_name
      db_instance_id     = aws_db_instance.url_shortener_db.identifier
      base_url           = "https://www.url-shortener.p-e.kr"
      cognito_issuer_uri = local.cognito_issuer_uri
    }
  ))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "URL Shortener Backend"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
