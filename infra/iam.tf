# --- IAM Role das instâncias K3s (acesso a SSM) ---
# OIDC e roles de CI/CD ficam no projeto bootstrap.
resource "aws_iam_role" "k3s" {
  name = "${local.name_prefix}-k3s-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy" "k3s_ssm" {
  name = "${local.name_prefix}-k3s-ssm"
  role = aws_iam_role.k3s.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:PutParameter",
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${local.env}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:DescribeParameters"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
        ]
        Resource = aws_sqs_queue.loan_events.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "k3s" {
  name = "${local.name_prefix}-k3s-profile"
  role = aws_iam_role.k3s.name
  tags = local.common_tags
}
