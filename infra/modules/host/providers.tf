terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
    }
    random = {
      source = "hashicorp/random"
    }
    b2 = {
      source = "registry.terraform.io/backblaze/b2"
    }
  }
}
