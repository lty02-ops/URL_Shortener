resource "aws_s3_bucket" "url_shortener_bucket" {
  bucket = "url-shortener-bucket-02"

  tags = {
    Name = "URL Shortener Bucket"
  }
}

resource "aws_cloudfront_distribution" "url_shortener_distribution" {
  origin {
    domain_name = aws_s3_bucket.url_shortener_bucket.bucket_regional_domain_name
    origin_id   = "S3-url-shortener-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.url_shortener_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "URL Shortener CloudFront Distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-url-shortener-bucket"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "URL Shortener CloudFront Distribution"
  }
}

resource "aws_cloudfront_origin_access_identity" "url_shortener_oai" {
  comment = "OAI for URL Shortener CloudFront Distribution"
}

resource "aws_s3_bucket_policy" "url_shortener_bucket_policy" {
  bucket = aws_s3_bucket.url_shortener_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.url_shortener_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.url_shortener_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.url_shortener_bucket.id
  key          = "index.html"
  source       = "${path.module}/../../frontend/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "style" {
  bucket       = aws_s3_bucket.url_shortener_bucket.id
  key          = "style.css"
  source       = "${path.module}/../../frontend/style.css"
  content_type = "text/css"
}

resource "aws_s3_object" "script" {
  bucket       = aws_s3_bucket.url_shortener_bucket.id
  key          = "script.js"
  source       = "${path.module}/../../frontend/script.js"
  content_type = "application/javascript"
}
