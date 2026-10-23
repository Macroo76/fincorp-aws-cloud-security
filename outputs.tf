
output "vpc_id" {
  description = "ID of the FinCorp VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets"
  value       = aws_subnet.private_db[*].id
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.app.dns_name
}

output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL database"
  value       = aws_db_instance.postgres.endpoint
}

output "application_instance_ids" {
  description = "IDs of the application EC2 instances"
  value       = aws_instance.app[*].id
}
