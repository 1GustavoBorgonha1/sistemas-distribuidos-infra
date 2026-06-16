output "state_bucket" {
  value       = aws_s3_bucket.tfstate.bucket
  description = "Bucket do state remoto — preencher em infra/backend.hcl"
}

output "lock_table" {
  value       = aws_dynamodb_table.tfstate_lock.name
  description = "Tabela de lock — preencher em infra/backend.hcl"
}

output "github_role_infra_arn" {
  value       = aws_iam_role.github_infra.arn
  description = "Secret AWS_ROLE_ARN_INFRA no repo de infra"
}

output "github_role_backend_arn" {
  value       = aws_iam_role.github_backend.arn
  description = "Secret AWS_ROLE_ARN no repo de backend"
}

output "github_role_frontend_arn" {
  value       = var.create_frontend_role ? aws_iam_role.github_frontend[0].arn : null
  description = "Secret AWS_ROLE_ARN no repo de frontend"
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}
