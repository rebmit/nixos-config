variable "name" {
  type = string
}

variable "script" {
  type = string
}

variable "account_id" {
  type = string
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

resource "cloudflare_record" "dns" {
  name    = "${var.name}.rebmit"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  content = "fallback.workers.moe"
  zone_id = var.zone_id
}

resource "cloudflare_workers_route" "workers" {
  script_name = cloudflare_workers_script.workers.name
  pattern     = "${cloudflare_record.dns.hostname}/*"
  zone_id     = var.zone_id
}

resource "cloudflare_workers_script" "workers" {
  name       = var.name
  content    = var.script
  account_id = var.account_id
  module     = true
}

resource "cloudflare_custom_hostname" "workers" {
  zone_id  = var.zone_id
  hostname = "${var.name}.rebmit.workers.moe"
  ssl {
    method = "http"
  }
}
