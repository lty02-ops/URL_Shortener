output "autoscaling_group_name" {
  value       = aws_autoscaling_group.backend.name
  description = "Backend Auto Scaling Group name"
}

output "launch_template_id" {
  value       = aws_launch_template.backend.id
  description = "Backend EC2 Launch Template ID"
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

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.url_shortener_distribution.id
  description = "CloudFront distribution ID"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.backend.repository_url
  description = "Backend ECR repository URL"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM role ARN to save as the AWS_GITHUB_ACTIONS_ROLE_ARN GitHub Actions secret"
}

output "certificate_validation_records" {
  description = "DNS records required to validate the ACM certificate"

  value = {
    for option in aws_acm_certificate.cloudfront.domain_validation_options :
    option.domain_name => {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  }
}

output "cloudfront_certificate_arn" {
  value       = aws_acm_certificate.cloudfront.arn
  description = "CloudFront ACM certificate ARN"
}
