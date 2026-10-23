
# ============================================================
# FinCore - IAM Groups
# ============================================================

resource "aws_iam_group" "dev" {
  name = "${local.name}-developers"
}

resource "aws_iam_group" "finance" {
  name = "${local.name}-finance"
}

resource "aws_iam_group" "operations" {
  name = "${local.name}-operations"
}

# ============================================================
# Developer Permission Boundary
# ============================================================

resource "aws_iam_policy" "developer_boundary" {
  name = "${local.name}-developer-boundary"

  policy = file(
    "${path.module}/Policies/developer_boundary.json"
  )
}

# ============================================================
# Department IAM Users
# ============================================================

resource "aws_iam_user" "dev_alice" {
  name                 = "dev-alice"
  permissions_boundary = aws_iam_policy.developer_boundary.arn

  tags = {
    Department = "Development"
    Role       = "Developer"
  }
}
resource "aws_iam_user" "sec-max" {
  name                 = "sec-max"

  tags = {
    Department = "Security"
    Role       = "SOC"
  }
}

resource "aws_iam_user" "dev_bob" {
  name                 = "dev-bob"
  permissions_boundary = aws_iam_policy.developer_boundary.arn

  tags = {
    Department = "Development"
    Role       = "Developer"
  }
}

resource "aws_iam_user" "dev_charlie" {
  name                 = "dev-charlie"
  permissions_boundary = aws_iam_policy.developer_boundary.arn

  tags = {
    Department = "Development"
    Role       = "Developer"
  }
}

resource "aws_iam_user" "dev_david" {
  name                 = "dev-david"
  permissions_boundary = aws_iam_policy.developer_boundary.arn

  tags = {
    Department = "Development"
    Role       = "Developer"
  }
}

resource "aws_iam_user" "fin_emma" {
  name = "fin-emma"

  tags = {
    Department = "Finance"
    Role       = "Finance Analyst"
  }
}

resource "aws_iam_user" "fin_frank" {
  name = "fin-frank"

  tags = {
    Department = "Finance"
    Role       = "Finance Analyst"
  }
}

resource "aws_iam_user" "op_george" {
  name = "op-george"

  tags = {
    Department = "Operations"
    Role       = "Operations Engineer"
  }
}

resource "aws_iam_user" "op_henry" {
  name = "op-henry"

  tags = {
    Department = "Operations"
    Role       = "Operations Engineer"
  }
}

resource "aws_iam_user" "op_irene" {
  name = "op-irene"

  tags = {
    Department = "Operations"
    Role       = "Operations Engineer"
  }
}

# ============================================================
# Group Memberships
# ============================================================

resource "aws_iam_group_membership" "developers" {
  name = "${local.name}-developers-membership"

  users = [
    aws_iam_user.dev_alice.name,
    aws_iam_user.dev_bob.name,
    aws_iam_user.dev_charlie.name,
    aws_iam_user.dev_david.name
  ]

  group = aws_iam_group.dev.name
}

resource "aws_iam_group_membership" "finance" {
  name = "${local.name}-finance-membership"

  users = [
    aws_iam_user.fin_emma.name,
    aws_iam_user.fin_frank.name
  ]

  group = aws_iam_group.finance.name
}

resource "aws_iam_group_membership" "operations" {
  name = "${local.name}-operations-membership"

  users = [
    aws_iam_user.op_george.name,
    aws_iam_user.op_henry.name,
    aws_iam_user.op_irene.name
  ]

  group = aws_iam_group.operations.name
}


# ============================================================
# FinCorp - Department Group Policies
# ============================================================

resource "aws_iam_policy" "dev" {
  name   = "${local.name}-dev-policy"
  policy = file("${path.module}/Policies/dev.json")
}

resource "aws_iam_policy" "finance" {
  name   = "${local.name}-finance-policy"
  policy = file("${path.module}/Policies/finance.json")
}


resource "aws_iam_policy" "operations" {
  name = "${local.name}-operations-policy"

  policy = templatefile(
    "${path.module}/Policies/operations.json",
    {
      region  = data.aws_region.current.region
      account = data.aws_caller_identity.current.account_id
    }
  )
}



resource "aws_iam_user_policy" "sec_max_cloudtrail_read" {
  name = "sec-max-cloudtrail-read-only"
  user = aws_iam_user.sec-max.name

  policy = templatefile(
    "${path.module}/policies/sec-max-cloudtrail-read-only.json",
    {
      logs_bucket_arn = aws_s3_bucket.logs.arn
    }
  )
}

# ============================================================
# Attach Policies to IAM Groups
# ============================================================

resource "aws_iam_group_policy_attachment" "dev" {
  group      = aws_iam_group.dev.name
  policy_arn = aws_iam_policy.dev.arn
}

resource "aws_iam_group_policy_attachment" "finance" {
  group      = aws_iam_group.finance.name
  policy_arn = aws_iam_policy.finance.arn
}

resource "aws_iam_group_policy_attachment" "operations" {
  group      = aws_iam_group.operations.name
  policy_arn = aws_iam_policy.operations.arn
}
