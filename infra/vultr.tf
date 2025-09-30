provider "vultr" {
  api_key = local.secrets.vultr.api_key
}

locals {
  vultr_nodes = {
    "reisen-fra0" = {
      region = "fra"
      plan   = "vhp-1c-1gb-amd"
    }
    "reisen-nrt0" = {
      region = "nrt"
      plan   = "vhp-1c-1gb-amd"
    }
    "reisen-sea0" = {
      region = "sea"
      plan   = "vhp-1c-1gb-amd"
    }
    "reisen-sin0" = {
      region = "sgp"
      plan   = "vhp-1c-1gb-amd"
    }
  }
}

resource "vultr_ssh_key" "marisa-7d76" {
  name    = "rebmit@marisa-7d76"
  ssh_key = trim(file("${path.module}/../nixos/profiles/users/root/_ssh/marisa-7d76"), "\n ")
}

module "vultr_instances" {
  source   = "./modules/vultr-instance"
  for_each = local.vultr_nodes
  hostname = each.key
  fqdn     = "${each.key}.rebmit.link"
  region   = each.value.region
  plan     = each.value.plan
  ssh_keys = [vultr_ssh_key.marisa-7d76.id]
}
