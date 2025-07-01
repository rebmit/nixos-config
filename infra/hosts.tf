locals {
  hosts = {
    "flandre-m5p" = {
      labels                     = ["enthalpy/edge"]
      endpoints_v4               = []
      endpoints_v6               = []
      enthalpy_node_id           = parseint("a23", 16)
      enthalpy_node_organization = "edge"
    }
    "marisa-7d76" = {
      labels                     = ["enthalpy/edge"]
      endpoints_v4               = []
      endpoints_v6               = []
      enthalpy_node_id           = parseint("d79", 16)
      enthalpy_node_organization = "edge"
    }
    "marisa-j715" = {
      labels                     = ["enthalpy/edge"]
      endpoints_v4               = []
      endpoints_v6               = []
      enthalpy_node_id           = parseint("572", 16)
      enthalpy_node_organization = "edge"
    }
    "kogasa-iad0" = {
      labels                     = []
      endpoints_v4               = ["152.53.167.21"]
      endpoints_v6               = ["2a0a:4cc0:2000:9bab::1"]
      enthalpy_node_id           = null
      enthalpy_node_organization = null
    }
    "kanako-ham0" = {
      labels                     = []
      endpoints_v4               = ["91.108.80.168"]
      endpoints_v6               = ["2a05:901:6:1015::1"]
      enthalpy_node_id           = null
      enthalpy_node_organization = null
    }
    "suwako-vie1" = {
      labels                     = ["dns/primary"]
      endpoints_v4               = ["46.102.157.144"]
      endpoints_v6               = ["2a0d:f302:102:8e05::1"]
      enthalpy_node_id           = null
      enthalpy_node_organization = null
    }
    "reisen-sea0" = {
      labels                     = ["dns/secondary", "enthalpy/core", "bgp/vultr"]
      endpoints_v4               = [module.vultr_instances["reisen-sea0"].ipv4]
      endpoints_v6               = [module.vultr_instances["reisen-sea0"].ipv6]
      enthalpy_node_id           = parseint("6b8", 16)
      enthalpy_node_organization = "core"
    }
    "reisen-nrt0" = {
      labels                     = ["dns/secondary", "enthalpy/core", "bgp/vultr"]
      endpoints_v4               = [module.vultr_instances["reisen-nrt0"].ipv4]
      endpoints_v6               = [module.vultr_instances["reisen-nrt0"].ipv6]
      enthalpy_node_id           = parseint("586", 16)
      enthalpy_node_organization = "core"
    }
    "reisen-sin0" = {
      labels                     = ["dns/secondary", "enthalpy/core", "bgp/vultr"]
      endpoints_v4               = [module.vultr_instances["reisen-sin0"].ipv4]
      endpoints_v6               = [module.vultr_instances["reisen-sin0"].ipv6]
      enthalpy_node_id           = parseint("254", 16)
      enthalpy_node_organization = "core"
    }
  }
}

module "hosts" {
  source                     = "./modules/host"
  for_each                   = local.hosts
  name                       = each.key
  labels                     = each.value.labels
  endpoints_v4               = each.value.endpoints_v4
  endpoints_v6               = each.value.endpoints_v6
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

output "nameservers" {
  value = {
    primary   = one([for k, v in local.hosts : k if contains(v.labels, "dns/primary")])
    secondary = [for k, v in local.hosts : k if contains(v.labels, "dns/secondary")]
  }
  sensitive = false
}
