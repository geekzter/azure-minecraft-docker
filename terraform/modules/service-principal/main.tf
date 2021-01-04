resource random_string password {
  length                       = 12
  upper                        = true
  lower                        = true
  number                       = true
  special                      = true
  override_special             = "." 
}

resource azuread_application app {
  name                         = var.name
  homepage                     = "https://${var.name}"
  identifier_uris              = ["http://${var.name}"]
  reply_urls                   = ["http://${var.name}/replyignored"]
  available_to_other_tenants   = false
  oauth2_allow_implicit_flow   = false
}

resource azuread_service_principal spn {
  application_id               = azuread_application.app.application_id
}

resource time_rotating secret_expiration {
  rotation_years               = 1
}

resource azuread_service_principal_password spnsecret {
  service_principal_id         = azuread_service_principal.spn.id
  value                        = random_string.password.result
  end_date                     = timeadd(time_rotating.secret_expiration.id, "8760h") # One year from now
}