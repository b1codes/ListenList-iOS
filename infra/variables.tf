variable "aws_region" {
  description = "The target AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Application tier environment tag"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "The base name of the application"
  type        = string
  default     = "listenlist"
}
