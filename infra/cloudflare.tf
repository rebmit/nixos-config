provider "cloudflare" {
  api_token = local.secrets.cloudflare.api_token
}

locals {
  cloudflare_main_account_id = local.secrets.cloudflare.account_id
  cloudflare_workers_zone_id = local.secrets.cloudflare.zone_id
}

# ------------------------------------
# authenticated origin pulls - common

resource "cloudflare_authenticated_origin_pulls" "default" {
  zone_id = local.cloudflare_workers_zone_id
  enabled = true
}

# ------------------------------------
# custom hostname ssl - common

resource "cloudflare_record" "fallback" {
  name    = "fallback"
  proxied = true
  ttl     = 1
  type    = "AAAA"
  content = "100::"
  zone_id = local.cloudflare_workers_zone_id
}

resource "cloudflare_custom_hostname_fallback_origin" "fallback" {
  zone_id = local.cloudflare_workers_zone_id
  origin  = "fallback.workers.moe"
}

# ------------------------------------
# cloudflare workers - mirror

module "cloudflare_workers_mirror" {
  source     = "./modules/cloudflare-workers"
  name       = "mirror"
  script     = file("${path.module}/resources/cloudflare-workers/mirror.js")
  account_id = local.cloudflare_main_account_id
  zone_id    = local.cloudflare_workers_zone_id
}

# ------------------------------------
# cloudflare reverse proxy - common

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

output "cloudflare_aop_certificate" {
  value     = tls_self_signed_cert.cloudflare_aop_ca.cert_pem
  sensitive = false
}

# ------------------------------------
# cloudflare reverse proxy - ntfy

module "cloudflare_reverse_proxy_ntfy" {
  source             = "./modules/cloudflare-reverse-proxy"
  name               = "ntfy"
  ca_private_key_pem = tls_private_key.cloudflare_aop_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.cloudflare_aop_ca.cert_pem
  ipv4               = [module.vultr_instances["reisen-nrt0"].ipv4]
  ipv6               = [module.vultr_instances["reisen-nrt0"].ipv6]
  zone_id            = local.cloudflare_workers_zone_id
}

output "cloudflare_origin_ntfy_certificate" {
  value     = module.cloudflare_reverse_proxy_ntfy.origin_certificate
  sensitive = false
}

output "cloudflare_origin_ntfy_private_key" {
  value     = module.cloudflare_reverse_proxy_ntfy.origin_private_key
  sensitive = true
}
