output "identity_account_id" {
  description = "FinCore Identity AWS account ID"
  value       = aws_organizations_account.identity.id
}

output "development_account_id" {
  description = "FinCore Development AWS account ID"
  value       = aws_organizations_account.development.id
}

output "finance_account_id" {
  description = "FinCore Finance AWS account ID"
  value       = aws_organizations_account.finance.id
}

output "operations_account_id" {
  description = "FinCore Operations AWS account ID"
  value       = aws_organizations_account.operations.id
}

output "logs_account_id" {
  description = "FinCore Logs AWS account ID"
  value       = aws_organizations_account.logs.id
}
