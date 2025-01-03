variable "name" {
  type = string
}

variable "hostname" {
  type = list(string)
}

variable "policies" {
  type = list(string)
}

variable "zone_id" {
  type = string
}

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

resource "cloudflare_zero_trust_access_application" "default" {
  zone_id                   = var.zone_id
  name                      = var.name
  domain                    = var.hostname[0]
  type                      = "self_hosted"
  session_duration          = "144h"
  auto_redirect_to_identity = false
  policies                  = var.policies

  dynamic "destinations" {
    for_each = var.hostname
    content {
      uri = destinations.value
    }
  }
}

resource "cloudflare_custom_hostname" "default" {
  for_each = toset(var.hostname)
  zone_id  = var.zone_id
  hostname = each.value
  ssl {
    method = "http"
  }
}
