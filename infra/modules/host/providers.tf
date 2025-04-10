terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
    }
    random = {
      source = "hashicorp/random"
    }
    b2 = {
      source = "backblaze/b2"
    }
  }
}
