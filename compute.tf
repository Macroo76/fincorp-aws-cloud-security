
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_iam_role" "ec2" {
  name = "${local.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "app" {
  count = 2

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private_app[count.index].id

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2.name
  #key_name             = aws_key_pair.ec2_ssh.key_name

  user_data = <<-EOF
    #!/bin/bash

    # Install and start SSM Agent
    for i in {1..5}; do
        if dnf install -y amazon-ssm-agent; then
            break
        fi
        sleep 10
    done

    systemctl enable --now amazon-ssm-agent

    # Install and start Nginx
    dnf install -y nginx

    systemctl enable nginx
    systemctl start nginx

    echo "<h1>FinCore Application Server ${count.index + 1}</h1>" > /usr/share/nginx/html/index.html
  EOF

  depends_on = [
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages
  ]

  user_data_replace_on_change = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-app-${count.index + 1}"
    Role = "Application"
  })
}
