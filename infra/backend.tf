terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  encryption {
    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.key_20250602
    }
    state {
      method   = method.aes_gcm.default
      enforced = true
    }
    plan {
      method   = method.aes_gcm.default
      enforced = true
    }
  }
}
