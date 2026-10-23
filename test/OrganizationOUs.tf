data "aws_organizations_organization" "current" {}

resource "aws_organizations_organizational_unit" "identity" {
  name      = "Identity"
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_organizational_unit" "development" {
  name      = "Development"
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_organizational_unit" "finance" {
  name      = "Finance"
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_organizational_unit" "operations" {
  name      = "Operations"
  parent_id = data.aws_organizations_organization.current.roots[0].id
}