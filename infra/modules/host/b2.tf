resource "b2_bucket" "backup" {
  bucket_name = "rebmit-backup-${var.name}"
  bucket_type = "allPrivate"

  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }

  lifecycle_rules {
    file_name_prefix              = ""
    days_from_uploading_to_hiding = null
    days_from_hiding_to_deleting  = 1
  }
}

resource "b2_application_key" "backup" {
  key_name  = "backup-${var.name}-20250602"
  bucket_id = b2_bucket.backup.id
  capabilities = [
    "deleteFiles",
    "listBuckets",
    "listFiles",
    "readBucketEncryption",
    "readBuckets",
    "readFiles",
    "shareFiles",
    "writeBucketEncryption",
    "writeFiles"
  ]
}

output "b2_backup_bucket_name" {
  value     = b2_bucket.backup.bucket_name
  sensitive = false
}

output "b2_backup_application_key_id" {
  value     = b2_application_key.backup.application_key_id
  sensitive = true
}

output "b2_backup_application_key" {
  value     = b2_application_key.backup.application_key
  sensitive = true
}
