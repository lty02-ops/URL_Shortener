resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name       = "www.url-shortener.p-e.kr"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "URL Shortener CloudFront Certificate"
  }
}