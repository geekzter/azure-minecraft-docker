output backup_policy {
  value       = var.enable_backup ? azurerm_backup_policy_file_share.nightly.0.name : null
}
output backup_vault {
  value       = var.enable_backup ? azurerm_recovery_services_vault.backup.0.name : null
}

output container_group {
  value       = [for minecraft in module.minecraft : minecraft.container_group_name]
}
output container_group_id {
  value       = [for minecraft in module.minecraft : minecraft.container_group_id]
}
output container_log_command {
  value       = "az container logs --ids ${join(" ",[for minecraft in module.minecraft : minecraft.container_group_id])} --follow"
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
  value       = [for function in module.functions : function.function_name]
}

output location {
  value       = azurerm_resource_group.minecraft.location
}

output log_analytics_workspace_guid {
  value       = azurerm_log_analytics_workspace.monitor.workspace_id
}

output minecraft {
  sensitive   = true
  value       = merge(
    {
      for key in keys(var.minecraft_config) : key => merge(var.minecraft_config[key],module.functions[key],module.minecraft[key])
    },
    {
      for key in keys(var.minecraft_bedrock_config) : key => var.minecraft_bedrock_config[key]
    }
  )
}

output minecraft_bedrock {
  sensitive   = true
  value       = {for key in keys(var.minecraft_bedrock_config) : key => merge(var.minecraft_bedrock_config[key],module.minecraft_bedrock[key])}
}
output minecraft_java {
  sensitive   = true
  value       = {for key in keys(var.minecraft_config) : key => merge(var.minecraft_config[key],module.functions[key],module.minecraft[key])}
}

output minecraft_server_fqdn {
  value       = [for minecraft in module.minecraft : minecraft.minecraft_server_fqdn]
}
output minecraft_server_ip {
  value       = [for minecraft in module.minecraft : minecraft.minecraft_server_ip]
}
output minecraft_server_connection {
  value       = [for minecraft in module.minecraft : minecraft.minecraft_server_connection]
}
output minecraft_server_port {
  value       = [for minecraft in module.minecraft : minecraft.minecraft_server_port]
}
output minecraft_users {
  value       = var.minecraft_users
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
  value       = [for minecraft in module.minecraft : minecraft.container_data_share_name]
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