locals {
  hosts = {
    "flandre-m5p" = {
      endpoints_v4               = []
      endpoints_v6               = []
      enthalpy_node_id           = parseint("a23", 16)
      enthalpy_node_organization = "edge"
    }
    "marisa-7d76" = {
      endpoints_v4               = []
      endpoints_v6               = []
      enthalpy_node_id           = parseint("d79", 16)
      enthalpy_node_organization = "edge"
    }
    "marisa-a7s" = {
      endpoints_v4               = []
      endpoints_v6               = []
      enthalpy_node_id           = parseint("572", 16)
      enthalpy_node_organization = "edge"
    }
    "reisen-sin0" = {
      endpoints_v4               = ["194.156.163.233"]
      endpoints_v6               = ["2407:b9c0:e002:20b:26a3:f0ff:fe46:a4d0"]
      enthalpy_node_id           = parseint("267", 16)
      enthalpy_node_organization = "core"
    }
    "reisen-lax0" = {
      endpoints_v4               = ["38.175.109.149"]
      endpoints_v6               = ["2a0e:6901:110:276:5054:ff:fe81:ec3b"]
      enthalpy_node_id           = null
      enthalpy_node_organization = null
    }
    "kanako-hkg0" = {
      endpoints_v4               = ["103.214.22.143"]
      endpoints_v6               = ["2406:ef80:1:3c5e::1"]
      enthalpy_node_id           = parseint("f87", 16)
      enthalpy_node_organization = "core"
    }
    "suwako-vie0" = {
      endpoints_v4               = ["110.172.148.83"]
      endpoints_v6               = ["2a0d:f302:136:7d2a::1"]
      enthalpy_node_id           = parseint("763", 16)
      enthalpy_node_organization = "core"
    }
  }
}

module "hosts" {
  source                     = "./modules/host"
  for_each                   = local.hosts
  name                       = each.key
  endpoints_v4               = each.value.endpoints_v4
  endpoints_v6               = each.value.endpoints_v6
  enthalpy_network_prefix    = local.enthalpy_network_prefix
  enthalpy_organizations     = local.enthalpy_organizations
  enthalpy_private_key       = tls_private_key.enthalpy
  enthalpy_node_id           = each.value.enthalpy_node_id
  enthalpy_node_organization = each.value.enthalpy_node_organization
}

output "hosts" {
  value     = module.hosts
  sensitive = true
}

output "hosts_non_sensitive" {
  value = {
    for host, outputs in module.hosts :
    host => {
      for name, output in outputs :
      name => output if !issensitive(output)
    }
  }
  sensitive = false
}
