provider "cloudflare" {
  api_token = local.secrets.cloudflare.api_token
}

locals {
  cloudflare_main_account_id = local.secrets.cloudflare.account_id
  cloudflare_workers_zone_id = local.secrets.cloudflare.zone_id
}

resource "cloudflare_record" "dns" {
  name    = "fallback"
  proxied = true
  ttl     = 1
  type    = "AAAA"
  content = "100::"
  zone_id = local.cloudflare_workers_zone_id
}

resource "cloudflare_custom_hostname_fallback_origin" "default" {
  zone_id = local.cloudflare_workers_zone_id
  origin  = "fallback.workers.moe"
}

module "cloudflare_workers_mirror" {
  source     = "./modules/cloudflare-workers"
  name       = "mirror"
  script     = file("${path.module}/resources/cloudflare-workers/mirror.js")
  account_id = local.cloudflare_main_account_id
  zone_id    = local.cloudflare_workers_zone_id
}
