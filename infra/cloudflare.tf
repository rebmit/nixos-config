provider "cloudflare" {
  api_token = local.secrets.cloudflare.api_token
}

locals {
  cloudflare_main_account_id = local.secrets.cloudflare.account_id
  cloudflare_workers_zone_id = local.secrets.cloudflare.zone_id
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
