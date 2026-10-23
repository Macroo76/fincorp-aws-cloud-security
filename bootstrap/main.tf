data "aws_organizations_organization" "current" {}

locals {
  root_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_organizational_unit" "identity" {
  name      = "Identity"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "development" {
  name      = "Development"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "finance" {
  name      = "Finance"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "operations" {
  name      = "Operations"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = local.root_id
}

resource "aws_organizations_account" "identity" {
  name      = "FinCore Identity"
  email     = var.identity_account_email
  parent_id = aws_organizations_organizational_unit.identity.id
  role_name = "OrganizationAccountAccessRole"
}

resource "aws_organizations_account" "development" {
  name      = "FinCore Development"
  email     = var.development_account_email
  parent_id = aws_organizations_organizational_unit.development.id
  role_name = "OrganizationAccountAccessRole"
}

resource "aws_organizations_account" "finance" {
  name      = "FinCore Finance"
  email     = var.finance_account_email
  parent_id = aws_organizations_organizational_unit.finance.id
  role_name = "OrganizationAccountAccessRole"
}

resource "aws_organizations_account" "operations" {
  name      = "FinCore Operations"
  email     = var.operations_account_email
  parent_id = aws_organizations_organizational_unit.operations.id
  role_name = "OrganizationAccountAccessRole"
}

resource "aws_organizations_account" "logs" {
  name      = "FinCore Logs"
  email     = var.logs_account_email
  parent_id = aws_organizations_organizational_unit.security.id
  role_name = "OrganizationAccountAccessRole"
}
