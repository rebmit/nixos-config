resource "random_bytes" "knot_tsig_ddns" {
  length = 32
}

output "knot_tsig_ddns" {
  value     = random_bytes.knot_tsig_ddns.base64
  sensitive = true
}
