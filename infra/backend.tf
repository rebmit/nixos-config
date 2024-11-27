terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  encryption {
    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.default
    }
    state {
      method   = method.aes_gcm.default
      enforced = true
    }
  }
}
