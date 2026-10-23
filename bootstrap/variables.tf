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

variable "identity_account_email" {
  description = "Email for the FinCore Identity account"
  type        = string
}

variable "development_account_email" {
  description = "Email for the FinCore Development account"
  type        = string
}

variable "finance_account_email" {
  description = "Email for the FinCore Finance account"
  type        = string
}

variable "operations_account_email" {
  description = "Email for the FinCore Operations account"
  type        = string
}

variable "logs_account_email" {
  description = "Email for the FinCore Logs account"
  type        = string
}
