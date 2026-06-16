# --- Role: repo de infra → administra a infra do app ---
resource "aws_iam_role" "github_infra" {
  name = "${var.project_name}-gha-infra"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.infra_repo_name}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "github_infra_admin" {
  role       = aws_iam_role.github_infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- Role: repo de backend → lê kubeconfig do SSM e atualiza o K3s ---
resource "aws_iam_role" "github_backend" {
  name = "${var.project_name}-gha-backend"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.backend_repo_name}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy" "github_backend" {
  name = "${var.project_name}-gha-backend-policy"
  role = aws_iam_role.github_backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.env}/*"
    }]
  })
}

# --- Role: repo de frontend → deploy S3 + invalidação CloudFront ---
resource "aws_iam_role" "github_frontend" {
  count = var.create_frontend_role ? 1 : 0
  name  = "${var.project_name}-gha-frontend"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.frontend_repo_name}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = local.common_tags
}

# Política por convenção de nome (não referencia recursos da camada infra,
# para não acoplar as duas camadas).
resource "aws_iam_role_policy" "github_frontend" {
  count = var.create_frontend_role ? 1 : 0
  name  = "${var.project_name}-gha-frontend-policy"
  role  = aws_iam_role.github_frontend[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"]
        Resource = "arn:aws:s3:::${var.project_name}-frontend-${var.env}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.project_name}-frontend-${var.env}"
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = "*"
      }
    ]
  })
}
