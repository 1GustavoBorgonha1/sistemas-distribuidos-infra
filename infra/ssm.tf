# --- JWT secret (consumido pelo master para criar o Secret do K8s) ---
resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/${local.env}/app/jwt_secret"
  type  = "SecureString"
  value = var.jwt_secret
  tags  = local.common_tags
}

# --- Preenchidos pelo bootstrap do master (placeholders) ---
resource "aws_ssm_parameter" "k3s_token" {
  name  = "/${local.env}/k3s/token"
  type  = "SecureString"
  value = "bootstrap-placeholder"

  lifecycle {
    ignore_changes = [value]
  }
  tags = local.common_tags
}

resource "aws_ssm_parameter" "k3s_kubeconfig" {
  name  = "/${local.env}/k3s/kubeconfig"
  type  = "SecureString"
  value = "bootstrap-placeholder"

  lifecycle {
    ignore_changes = [value]
  }
  tags = local.common_tags
}
