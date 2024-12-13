terraform {
  required_providers {
    sops = {
      source = "registry.terraform.io/carlpett/sops"
    }
    tls = {
      source = "registry.terraform.io/hashicorp/tls"
    }
    random = {
      source = "registry.terraform.io/hashicorp/random"
    }
    cloudflare = {
      source = "registry.terraform.io/cloudflare/cloudflare"
    }
    b2 = {
      source = "registry.terraform.io/backblaze/b2"
    }
  }
}
