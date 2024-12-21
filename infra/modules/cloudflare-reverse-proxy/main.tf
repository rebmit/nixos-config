variable "name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "ca_private_key_pem" {
  type = string
}

variable "ca_cert_pem" {
  type = string
}

variable "ipv4" {
  type = list(string)
}

variable "ipv6" {
  type = list(string)
}

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

resource "tls_private_key" "aop" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "aop" {
  private_key_pem = tls_private_key.aop.private_key_pem
  dns_names       = ["${var.name}.rebmit.workers.moe"]
  subject {
    common_name  = "${var.name}.rebmit.workers.moe"
    organization = "rebmit"
  }
}

resource "tls_locally_signed_cert" "aop" {
  cert_request_pem   = tls_cert_request.aop.cert_request_pem
  ca_private_key_pem = var.ca_private_key_pem
  ca_cert_pem        = var.ca_cert_pem

  validity_period_hours = 1460 # 2 months
  early_renewal_hours   = 730  # 1 months
  allowed_uses = [
    "client_auth"
  ]
}

resource "cloudflare_authenticated_origin_pulls_certificate" "aop" {
  zone_id     = var.zone_id
  certificate = tls_locally_signed_cert.aop.cert_pem
  private_key = tls_private_key.aop.private_key_pem
  type        = "per-hostname"
}

resource "cloudflare_authenticated_origin_pulls" "aop" {
  zone_id                                = var.zone_id
  authenticated_origin_pulls_certificate = cloudflare_authenticated_origin_pulls_certificate.aop.id
  hostname                               = "${var.name}.rebmit.workers.moe"
  enabled                                = true
}

resource "tls_private_key" "origin" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "origin" {
  private_key_pem = tls_private_key.origin.private_key_pem

  subject {
    common_name  = "${var.name}.rebmit.workers.moe"
    organization = "rebmit"
  }
}

resource "cloudflare_origin_ca_certificate" "origin" {
  csr                = tls_cert_request.origin.cert_request_pem
  hostnames          = ["${var.name}.rebmit.workers.moe"]
  request_type       = "origin-ecc"
  requested_validity = 90
}

resource "cloudflare_custom_hostname" "proxy" {
  zone_id  = var.zone_id
  hostname = "${var.name}.rebmit.workers.moe"
  ssl {
    method = "http"
  }
}

resource "cloudflare_record" "proxy_a" {
  name     = "${var.name}.rebmit"
  for_each = toset(var.ipv4)
  proxied  = true
  ttl      = 1
  type     = "A"
  content  = each.value
  zone_id  = var.zone_id
}

resource "cloudflare_record" "proxy_aaaa" {
  name     = "${var.name}.rebmit"
  for_each = toset(var.ipv6)
  proxied  = true
  ttl      = 1
  type     = "AAAA"
  content  = each.value
  zone_id  = var.zone_id
}

output "origin_certificate" {
  value     = cloudflare_origin_ca_certificate.origin.certificate
  sensitive = false
}

output "origin_private_key" {
  value     = tls_private_key.origin.private_key_pem
  sensitive = true
}
