provider "b2" {
  application_key_id = local.secrets.b2.application_key_id
  application_key    = local.secrets.b2.application_key
}
