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
# cloudflare zero trust - common

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

resource "cloudflare_zero_trust_access_identity_provider" "oidc_keycloak" {
  account_id = local.cloudflare_main_account_id
  name       = "Keycloak"
  type       = "oidc"
  config {
    client_id     = "cloudflare"
    client_secret = local.secrets.cloudflare.keycloak_oidc_secret
    auth_url      = "https://keycloak.rebmit.moe/realms/rebmit/protocol/openid-connect/auth"
    token_url     = "https://keycloak.rebmit.moe/realms/rebmit/protocol/openid-connect/token"
    certs_url     = "https://keycloak.rebmit.moe/realms/rebmit/protocol/openid-connect/certs"
    scopes        = ["openid", "email", "profile"]
  }
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

output "cloudflare_aop_ca_certificate" {
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

# ------------------------------------
# cloudflare reverse proxy - prometheus

module "cloudflare_reverse_proxy_prometheus" {
  source             = "./modules/cloudflare-reverse-proxy"
  name               = "prometheus"
  ca_private_key_pem = tls_private_key.cloudflare_aop_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.cloudflare_aop_ca.cert_pem
  ipv4               = [module.vultr_instances["reisen-nrt0"].ipv4]
  ipv6               = [module.vultr_instances["reisen-nrt0"].ipv6]
  zone_id            = local.cloudflare_workers_zone_id
}

output "cloudflare_origin_prometheus_certificate" {
  value     = module.cloudflare_reverse_proxy_prometheus.origin_certificate
  sensitive = false
}

output "cloudflare_origin_prometheus_private_key" {
  value     = module.cloudflare_reverse_proxy_prometheus.origin_private_key
  sensitive = true
}

resource "cloudflare_zero_trust_access_application" "prometheus" {
  zone_id                   = local.cloudflare_workers_zone_id
  name                      = "Prometheus"
  domain                    = "prometheus.rebmit.workers.moe"
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = false
  policies = [
    cloudflare_zero_trust_access_policy.default.id
  ]
}

# ------------------------------------
# cloudflare rulesets - redirects

resource "cloudflare_custom_hostname" "ntfy" {
  zone_id  = local.cloudflare_workers_zone_id
  hostname = "ntfy.rebmit.moe"
  ssl {
    method = "http"
  }
}

resource "cloudflare_custom_hostname" "prometheus" {
  zone_id  = local.cloudflare_workers_zone_id
  hostname = "prometheus.rebmit.moe"
  ssl {
    method = "http"
  }
}

resource "cloudflare_ruleset" "bulk_redirects" {
  account_id = local.cloudflare_main_account_id
  name       = "bulk_redirects"
  kind       = "root"
  phase      = "http_request_redirect"

  rules {
    action = "redirect"
    action_parameters {
      from_list {
        name = cloudflare_list.bulk_redirects.name
        key  = "http.request.full_uri"
      }
    }
    expression = "http.request.full_uri in $bulk_redirects"
    enabled    = true
  }
}

resource "cloudflare_list" "bulk_redirects" {
  account_id = local.cloudflare_main_account_id
  name       = "bulk_redirects"
  kind       = "redirect"

  dynamic "item" {
    for_each = toset(["ntfy", "prometheus"])
    content {
      value {
        redirect {
          source_url            = "${item.key}.rebmit.moe"
          target_url            = "https://${item.key}.rebmit.workers.moe"
          status_code           = 301
          include_subdomains    = "disabled"
          subpath_matching      = "enabled"
          preserve_query_string = "enabled"
          preserve_path_suffix  = "enabled"
        }
      }
    }
  }
}
