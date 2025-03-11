variable "enthalpy_organizations" {
  type = map(string)
}

variable "enthalpy_private_key" {
  type = map(object({
    private_key_pem = string
  }))
}

variable "enthalpy_node_id" {
  type = number
}

variable "enthalpy_node_organization" {
  type = string
}

locals {
  enthalpy_node_enabled         = var.enthalpy_node_id != null && var.enthalpy_node_organization != null
  enthalpy_node_organization    = local.enthalpy_node_enabled ? var.enthalpy_organizations[var.enthalpy_node_organization] : null
  enthalpy_node_private_key_pem = local.enthalpy_node_enabled ? var.enthalpy_private_key[var.enthalpy_node_organization].private_key_pem : null
}

output "enthalpy_node_id" {
  value     = var.enthalpy_node_id
  sensitive = false
}

output "enthalpy_node_organization" {
  value     = local.enthalpy_node_organization
  sensitive = false
}

output "enthalpy_node_private_key_pem" {
  value     = local.enthalpy_node_private_key_pem
  sensitive = true
}
