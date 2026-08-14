variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-2"
}

variable "alarm_email" {
  description = "CloudWatch alarm notification email"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to deploy the backend"
  type        = string
  default     = "lty02-ops/URL_Shortener"
}

variable "github_branch" {
  description = "GitHub branch allowed to deploy the backend"
  type        = string
  default     = "main"
}
