
resource "aws_db_subnet_group" "main" {
  name = "${local.name}-db-subnet-group"

  subnet_ids = aws_subnet.private_db[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name}-db-subnet-group"
  })
}

resource "aws_db_instance" "postgres" {
  identifier = "${local.name}-postgres"
  
  engine                = "postgres"
  engine_version        = "16"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  publicly_accessible = false

  backup_retention_period         = 7
  enabled_cloudwatch_logs_exports = ["postgresql"]
  deletion_protection             = false
  skip_final_snapshot             = true

  storage_encrypted = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-postgres"
  })
}
