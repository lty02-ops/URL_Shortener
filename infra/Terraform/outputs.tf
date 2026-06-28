output "instance_id" {
  value       = aws_instance.url_shortener_instance.id
  description = "The ID of the EC2 instance"
}

output "public_ip" {
  value       = aws_instance.url_shortener_instance.public_ip
  description = "The public IP address of the EC2 instance"
}

output "public_dns" {
  value       = aws_instance.url_shortener_instance.public_dns
  description = "The public DNS name of the EC2 instance"
}

output "availability_zone" {
  value       = aws_instance.url_shortener_instance.availability_zone
  description = "The availability zone of the EC2 instance"
}

output "subnet_id" {
  value       = aws_instance.url_shortener_instance.subnet_id
  description = "The subnet ID of the EC2 instance"
}

output "db_endpoint" {
  value       = aws_db_instance.url_shortener_db.endpoint
  description = "The endpoint of the RDS instance"
}

output "alb_dns_name" {
  value = aws_lb.url_shortener_lb.dns_name
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.url_shortener_distribution.domain_name
}
