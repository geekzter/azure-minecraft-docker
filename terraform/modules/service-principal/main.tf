resource random_string password {
  length                       = 12
  upper                        = true
  lower                        = true
  number                       = true
  special                      = true
  override_special             = "." 
}

resource azuread_application app {
  display_name                 = var.name
  identifier_uris              = ["http://${var.name}"]
  sign_in_audience             = "AzureADMyOrg"

  web {
    homepage_url               = "https://${var.name}"
    implicit_grant {
      access_token_issuance_enabled = false
    }
    redirect_uris              = ["http://${var.name}/replyignored"]
  }
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