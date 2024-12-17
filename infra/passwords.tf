resource "random_bytes" "knot_ddns_tsig_secret" {
  length = 32
}

output "knot_ddns_tsig_secret" {
  value     = random_bytes.knot_ddns_tsig_secret.base64
  sensitive = true
}
