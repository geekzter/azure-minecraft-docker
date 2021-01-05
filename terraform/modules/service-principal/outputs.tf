output application_id {
  value       = azuread_application.app.application_id
}
output object_id {
  value       = azuread_service_principal.spn.object_id
}
output principal_id {
  value       = azuread_service_principal.spn.id
}
output secret {
  value       = azuread_service_principal_password.spnsecret.value
}