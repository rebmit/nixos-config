provider "cloudflare" {
  api_token = local.secrets.cloudflare.api_token
}

locals {
  cloudflare_main_account_id = local.secrets.cloudflare.account_id
  cloudflare_workers_zone_id = local.secrets.cloudflare.zone_id
}

# ------------------------------------
# authenticated origin pulls - common

resource "tls_private_key" "cloudflare_aop_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "cloudflare_aop_ca" {
  is_ca_certificate = true
  private_key_pem   = tls_private_key.cloudflare_aop_ca.private_key_pem
  subject {
    common_name  = "workers.moe"
    organization = "rebmit"
  }
  validity_period_hours = 8760 # 1 year
  early_renewal_hours   = 4320 # 6 months
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
}

output "cloudflare_aop_ca_certificate" {
  value     = tls_self_signed_cert.cloudflare_aop_ca.cert_pem
  sensitive = false
}

resource "tls_private_key" "cloudflare_aop_leaf" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "cloudflare_aop_leaf" {
  private_key_pem = tls_private_key.cloudflare_aop_leaf.private_key_pem
  dns_names       = ["*.rebmit.workers.moe", "*.rebmit.moe"]
  subject {
    common_name  = "workers.moe"
    organization = "rebmit"
  }
}

resource "tls_locally_signed_cert" "cloudflare_aop_leaf" {
  cert_request_pem   = tls_cert_request.cloudflare_aop_leaf.cert_request_pem
  ca_private_key_pem = tls_private_key.cloudflare_aop_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.cloudflare_aop_ca.cert_pem

  validity_period_hours = 4320 # 6 months
  early_renewal_hours   = 2160 # 3 months
  allowed_uses = [
    "client_auth"
  ]
}

resource "cloudflare_authenticated_origin_pulls" "default" {
  zone_id = local.cloudflare_workers_zone_id
  enabled = true
}

resource "cloudflare_authenticated_origin_pulls_certificate" "zone" {
  zone_id     = local.cloudflare_workers_zone_id
  certificate = tls_locally_signed_cert.cloudflare_aop_leaf.cert_pem
  private_key = tls_private_key.cloudflare_aop_leaf.private_key_pem
  type        = "per-zone"
}

resource "cloudflare_authenticated_origin_pulls" "zone" {
  zone_id                                = local.cloudflare_workers_zone_id
  authenticated_origin_pulls_certificate = cloudflare_authenticated_origin_pulls_certificate.zone.id
  enabled                                = true
}

# ------------------------------------
# custom hostname ssl - common

resource "cloudflare_record" "fallback_a" {
  for_each = toset(module.hosts["suwako-vie1"].endpoints_v4)
  name     = "fallback"
  proxied  = true
  ttl      = 1
  type     = "A"
  content  = each.value
  zone_id  = local.cloudflare_workers_zone_id
}

resource "cloudflare_record" "fallback_aaaa" {
  for_each = toset(module.hosts["suwako-vie1"].endpoints_v6)
  name     = "fallback"
  proxied  = true
  ttl      = 1
  type     = "AAAA"
  content  = each.value
  zone_id  = local.cloudflare_workers_zone_id
}

resource "cloudflare_custom_hostname_fallback_origin" "fallback" {
  zone_id = local.cloudflare_workers_zone_id
  origin  = "fallback.workers.moe"
}

# ------------------------------------
# zero trust - common

resource "cloudflare_zero_trust_access_policy" "default" {
  account_id = local.cloudflare_main_account_id
  name       = "Default Policy"
  decision   = "allow"

  include {
    email = [
      "rebmit@rebmit.moe",
      "rebmit233@outlook.com",
    ]
  }
}

resource "cloudflare_zero_trust_access_identity_provider" "pin_login" {
  account_id = local.cloudflare_main_account_id
  name       = "PIN login"
  type       = "onetimepin"
}

# ------------------------------------
# zero trust - prom

resource "cloudflare_record" "prom_a" {
  name     = "prom.rebmit"
  for_each = toset(module.hosts["suwako-vie1"].endpoints_v4)
  proxied  = true
  ttl      = 1
  type     = "A"
  content  = each.value
  zone_id  = local.cloudflare_workers_zone_id
}

resource "cloudflare_record" "prom_aaaa" {
  name     = "prom.rebmit"
  for_each = toset(module.hosts["suwako-vie1"].endpoints_v6)
  proxied  = true
  ttl      = 1
  type     = "AAAA"
  content  = each.value
  zone_id  = local.cloudflare_workers_zone_id
}

module "cloudflare_zero_trust_prom" {
  source   = "./modules/cloudflare-zero-trust"
  name     = "prom"
  hostname = ["prom.rebmit.workers.moe", "prom.rebmit.moe"]
  policies = [cloudflare_zero_trust_access_policy.default.id]
  zone_id  = local.cloudflare_workers_zone_id
}

# ------------------------------------
# dns only - push

resource "cloudflare_record" "push_a" {
  name     = "push.rebmit"
  for_each = toset(module.hosts["suwako-vie1"].endpoints_v4)
  proxied  = false
  ttl      = 1
  type     = "A"
  content  = each.value
  zone_id  = local.cloudflare_workers_zone_id
}

resource "cloudflare_record" "push_aaaa" {
  name     = "push.rebmit"
  for_each = toset(module.hosts["suwako-vie1"].endpoints_v6)
  proxied  = false
  ttl      = 1
  type     = "AAAA"
  content  = each.value
  zone_id  = local.cloudflare_workers_zone_id
}

resource "cloudflare_record" "push_https" {
  name    = "push.rebmit"
  proxied = false
  ttl     = 1
  type    = "HTTPS"
  zone_id = local.cloudflare_workers_zone_id

  data {
    priority = 1
    target   = "."
    value    = "alpn=\"h3,h2\""
  }
}
