variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-2"
}

variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}