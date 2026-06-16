# --- Certificado da API (backend) ---
resource "aws_acm_certificate" "api" {
  domain_name       = local.api_domain
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cert-api" })
}

resource "cloudflare_record" "api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      content = dvo.resource_record_value
      type    = dvo.resource_record_type
    }
  }
  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  ttl     = 60
  proxied = false
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for r in cloudflare_record.api_cert_validation : r.hostname]
}

# --- Certificado do Frontend ---
resource "aws_acm_certificate" "frontend" {
  domain_name       = local.front_domain
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-cert-frontend" })
}

resource "cloudflare_record" "frontend_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      content = dvo.resource_record_value
      type    = dvo.resource_record_type
    }
  }
  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  ttl     = 60
  proxied = false
}

resource "aws_acm_certificate_validation" "frontend" {
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for r in cloudflare_record.frontend_cert_validation : r.hostname]
}
