variable "name" {
  type = string
}

variable "hostname" {
  type = list(string)
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

resource "cloudflare_workers_route" "workers" {
  for_each    = toset(var.hostname)
  script_name = cloudflare_workers_script.workers.name
  pattern     = "${each.value}/*"
  zone_id     = var.zone_id
}

resource "cloudflare_workers_script" "workers" {
  name       = var.name
  content    = var.script
  account_id = var.account_id
  module     = true
}

resource "cloudflare_custom_hostname" "workers" {
  for_each = toset(var.hostname)
  zone_id  = var.zone_id
  hostname = each.value
  ssl {
    method = "http"
  }
}
