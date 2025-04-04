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

output "enthalpy" {
  value = {
    for key, name in local.enthalpy_organizations : name => {
      public_key_pem = trimspace(tls_private_key.enthalpy[key].public_key_pem)
      nodes          = [for k, v in local.hosts : k if contains(v.labels, "enthalpy/${key}")]
    }
  }
  sensitive = false
}
