provider "vultr" {
  api_key = local.secrets.vultr.api_key
}

resource "vultr_ssh_key" "marisa-7d76" {
  name    = "rebmit@marisa-7d76"
  ssh_key = file("${path.module}/../nixos/profiles/users/root/_ssh/marisa-7d76")
}
