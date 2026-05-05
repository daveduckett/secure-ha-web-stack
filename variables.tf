variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}


variable "credentials_username_password" {
  description = "Testing password credentials for the database"
  type        = object({
    username = string
    password = string
  })
  sensitive   = true
}