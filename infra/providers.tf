terraform {
  required_providers {
    sops = {
      source = "carlpett/sops"
    }
    tls = {
      source = "hashicorp/tls"
    }
    random = {
      source = "hashicorp/random"
    }
    b2 = {
      source = "registry.terraform.io/backblaze/b2"
    }
    vultr = {
      source = "vultr/vultr"
    }
  }
}
