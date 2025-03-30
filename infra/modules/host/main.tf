variable "name" {
  type = string
}

variable "labels" {
  type = list(string)
}

output "labels" {
  value     = var.labels
  sensitive = false
}
