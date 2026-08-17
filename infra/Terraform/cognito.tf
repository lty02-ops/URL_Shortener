data "aws_caller_identity" "current" {}

resource "aws_cognito_user_pool" "users" {
  name                     = "url-shortener-users"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name = "URL Shortener Users"
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "url-shortener-web"
  user_pool_id = aws_cognito_user_pool.users.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = ["https://www.url-shortener.p-e.kr/"]
  logout_urls                          = ["https://www.url-shortener.p-e.kr/"]

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_pool_domain" "users" {
  domain       = "url-shortener-${data.aws_caller_identity.current.account_id}"
  user_pool_id = aws_cognito_user_pool.users.id
}

locals {
  cognito_domain     = "https://${aws_cognito_user_pool_domain.users.domain}.auth.${var.region}.amazoncognito.com"
  cognito_issuer_uri = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
}
