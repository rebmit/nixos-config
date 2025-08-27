resource "random_bytes" "knot_ddns_tsig_secret" {
  length = 32
}

output "knot_ddns_tsig_secret" {
  value     = random_bytes.knot_ddns_tsig_secret.base64
  sensitive = true
}

resource "random_bytes" "knot_he_tsig_secret" {
  length = 32
}

output "knot_he_tsig_secret" {
  value     = random_bytes.knot_he_tsig_secret.base64
  sensitive = true
}

resource "random_bytes" "knot_reisen_tsig_secret" {
  length = 32
}

output "knot_reisen_tsig_secret" {
  value     = random_bytes.knot_reisen_tsig_secret.base64
  sensitive = true
}

resource "random_bytes" "knot_acme_tsig_secret" {
  length = 32
}

output "knot_acme_tsig_secret" {
  value     = random_bytes.knot_acme_tsig_secret.base64
  sensitive = true
}

resource "random_password" "heisenbridge_appservice_hs_token" {
  length  = 64
  special = false
}

output "heisenbridge_appservice_hs_token" {
  value     = random_password.heisenbridge_appservice_hs_token.result
  sensitive = true
}

resource "random_password" "heisenbridge_appservice_as_token" {
  length  = 64
  special = false
}

output "heisenbridge_appservice_as_token" {
  value     = random_password.heisenbridge_appservice_as_token.result
  sensitive = true
}

resource "random_password" "mautrix_telegram_appservice_hs_token" {
  length  = 64
  special = false
}

output "mautrix_telegram_appservice_hs_token" {
  value     = random_password.mautrix_telegram_appservice_hs_token.result
  sensitive = true
}

resource "random_password" "mautrix_telegram_appservice_as_token" {
  length  = 64
  special = false
}

output "mautrix_telegram_appservice_as_token" {
  value     = random_password.mautrix_telegram_appservice_as_token.result
  sensitive = true
}
