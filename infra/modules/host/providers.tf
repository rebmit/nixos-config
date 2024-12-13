terraform {
  required_providers {
    tls = {
      source = "registry.terraform.io/hashicorp/tls"
    }
    random = {
      source = "registry.terraform.io/hashicorp/random"
    }
    b2 = {
      source = "registry.terraform.io/backblaze/b2"
    }
  }
}
