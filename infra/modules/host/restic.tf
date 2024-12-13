resource "random_password" "restic" {
  length = 32
}

output "restic_password" {
  value     = random_password.restic.result
  sensitive = true
}
