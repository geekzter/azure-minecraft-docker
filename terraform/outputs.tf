output container_group {
  value       = azurerm_container_group.minecraft_server.name
}
output container_group_id {
  value       = azurerm_container_group.minecraft_server.id  
}
output container_log_command {
  value       = "az container logs --ids ${azurerm_container_group.minecraft_server.id} --follow"
}

output dashboard_id {
  value       = azurerm_dashboard.minecraft_dashboard.id
}
output dashboard_url {
  value       = "https://portal.azure.com/#@/dashboard/arm${azurerm_dashboard.minecraft_dashboard.id}"
}

output environment {
  value       = local.environment
}

output function_name {
  value        = [module.functions.function_name]
}

output location {
  value       = azurerm_resource_group.minecraft.location
}

output minecraft_server_fqdn {
  value       = local.minecraft_server_fqdn
}
output minecraft_server_ip {
  value       = azurerm_container_group.minecraft_server.ip_address
}
output minecraft_server_connection {
  value       = "${var.vanity_dns_zone_id != "" ? replace(try(azurerm_dns_cname_record.vanity_hostname.0.fqdn,""),"/\\W*$/","") : azurerm_container_group.minecraft_server.fqdn}:${local.minecraft_server_port}"
}
output minecraft_server_port {
  value       = local.minecraft_server_port
}
output minecraft_users {
  value       = var.minecraft_users
}
output minecraft_version {
  value       = var.minecraft_version
}

output resource_group {
  value       = azurerm_resource_group.minecraft.name
}
output resource_group_id {
  value       = azurerm_resource_group.minecraft.id
}
output resource_locks {
  value       = local.all_resource_locks
}
output resource_suffix {
  value       = local.suffix
}
output subscription_guid {
  value       = data.azurerm_subscription.primary.subscription_id
}

output subscription_id {
  value       = data.azurerm_subscription.primary.id
}

output storage_account {
  value       = azurerm_storage_account.minecraft.name
}
output storage_account_id {
  value       = azurerm_storage_account.minecraft.id
}
output storage_data_share {
  value       = azurerm_storage_share.minecraft_share.name
}
output storage_key {
  sensitive   = true
  value       = azurerm_storage_account.minecraft.primary_access_key
}
output workflow_sp_application_id {
  value       = local.workflow_sp_application_id
}
output workflow_sp_application_secret {
  sensitive   = true
  value       = local.workflow_sp_application_secret
}
output workspace {
  value       = terraform.workspace
}