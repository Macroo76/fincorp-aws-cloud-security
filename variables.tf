variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "fincore"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}


variable "db_name" {
  description = "Name of the FinCorp PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Master username for the PostgreSQL database"
  type        = string
}

variable "db_password" {
  description = "Master password for the PostgreSQL database"
  type        = string
  sensitive   = true
}


variable "vpc_cidr" {
  description = "CIDR block for the FinCorp VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones used by the FinCorp subnets"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}
