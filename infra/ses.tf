# --- Identidade de domínio no SES (envio em nome de @yan.tec.br) ---
resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.base_domain
}

# --- Registros DKIM no Cloudflare ---
resource "cloudflare_record" "ses_dkim" {
  for_each = toset(["0", "1", "2"])

  zone_id = var.cloudflare_zone_id
  name    = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[each.value]}._domainkey.${var.base_domain}"
  content = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[each.value]}.dkim.amazonses.com"
  type    = "CNAME"
  proxied = false
  ttl     = 60
}