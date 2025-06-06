variable "hostname" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "region" {
  type = string
}

variable "plan" {
  type = string
}

variable "ssh_keys" {
  type = list(string)
}

terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
  }
}

resource "vultr_instance" "server" {
  region           = var.region
  plan             = var.plan
  os_id            = 2284
  ssh_key_ids      = var.ssh_keys
  backups          = "disabled"
  enable_ipv6      = true
  activation_email = false
  ddos_protection  = false
  hostname         = var.fqdn
  label            = var.hostname
  lifecycle {
    ignore_changes = [
      os_id,
      ssh_key_ids,
    ]
  }
}

resource "vultr_reverse_ipv4" "reverse_ipv4" {
  instance_id = vultr_instance.server.id
  ip          = vultr_instance.server.main_ip
  reverse     = var.fqdn
}

resource "vultr_reverse_ipv6" "reverse_ipv6" {
  instance_id = vultr_instance.server.id
  ip          = vultr_instance.server.v6_main_ip
  reverse     = var.fqdn
}

output "ipv4" {
  value = vultr_reverse_ipv4.reverse_ipv4.ip
}

output "ipv6" {
  value = vultr_reverse_ipv6.reverse_ipv6.ip
}
