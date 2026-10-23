data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  name = "fincorp"

  common_tags = {
    Project     = "FinCorp"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}
