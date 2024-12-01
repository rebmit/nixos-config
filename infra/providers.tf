terraform {
  required_providers {
    sops = {
      source = "registry.terraform.io/carlpett/sops"
    }
    tls = {
      source = "registry.terraform.io/hashicorp/tls"
    }
    cloudflare = {
      source = "registry.terraform.io/cloudflare/cloudflare"
    }
  }
}
