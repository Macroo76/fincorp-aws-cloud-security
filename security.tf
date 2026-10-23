resource "aws_security_group" "alb" {

  name        = "${local.name}-alb-sg"
  description = "FinCore ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

egress {
  description     = "HTTP to application targets"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.app.id]
}

  tags = merge(local.common_tags, {
    Name = "${local.name}-alb-sg"
  })
}

resource "aws_security_group" "app" {

  name        = "${local.name}-app-sg"
  description = "FinCore application security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }


  tags = merge(local.common_tags, {
    Name = "${local.name}-app-sg"
  })
}

resource "aws_security_group" "db" {

  name        = "${local.name}-db-sg"
  description = "FinCore database security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from application"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-db-sg"
  })
}

resource "aws_security_group" "vpce" {

  name        = "${local.name}-vpce-sg"
  description = "Allow HTTPS from VPC to interface endpoints"
  vpc_id      = aws_vpc.main.id



  tags = merge(local.common_tags, {
    Name = "${local.name}-vpce-sg"
  })
}


resource "aws_vpc_security_group_ingress_rule" "vpce_from_app" {

  security_group_id            = aws_security_group.vpce.id
  referenced_security_group_id = aws_security_group.app.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "HTTPS from application instances"
}



resource "aws_vpc_security_group_egress_rule" "app_to_vpce" {

  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.vpce.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "HTTPS to SSM VPC endpoints"
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

resource "aws_vpc_security_group_egress_rule" "app_to_s3" {
  security_group_id = aws_security_group.app.id
  prefix_list_id    = data.aws_prefix_list.s3.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "HTTPS to Amazon S3 via Gateway Endpoint"
}