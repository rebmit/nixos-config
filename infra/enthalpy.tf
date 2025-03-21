locals {
  enthalpy_organizations = {
    core = "rebmit's core network"
    edge = "rebmit's edge network"
  }
}

resource "tls_private_key" "enthalpy" {
  for_each  = local.enthalpy_organizations
  algorithm = "ED25519"
}

output "enthalpy_organizations" {
  value     = local.enthalpy_organizations
  sensitive = false
}

output "enthalpy_public_key_pem" {
  value     = { for k, v in tls_private_key.enthalpy : k => trimspace(v.public_key_pem) }
  sensitive = false
}
