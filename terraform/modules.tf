# Provision base network infrastructure
module service_principal {
  source                       = "./modules/service-principal"
  name                         = "workflow-${terraform.workspace}-${local.suffix}"

  count                        = local.create_service_principal ? 1 : 0
}

module minecraft {
  source                       = "./modules/minecraft-instance"
  name                         = replace("${azurerm_resource_group.minecraft.name}-${each.key}","-primary","")
  # name                         = "${azurerm_resource_group.minecraft.name}-${each.key}"

  allow_ops_only               = tobool(lookup(each.value, "allow_ops_only", false))

  backup_policy_id             = var.enable_backup ? azurerm_backup_policy_file_share.nightly.0.id : null
  configuration_storage_container_name= azurerm_storage_container.configuration.name

  container_image_tag          = lookup(each.value, "container_image_tag", "LATEST")
  container_data_share_name    = replace("minecraft-aci-${each.key}-data-${local.suffix}","-primary","")
  container_modpacks_share_name= replace("minecraft-aci-${each.key}-modpacks-${local.suffix}","-primary","")
  environment_variables        = each.value["environment_variables"]

  environment                  = local.environment

  enable_backup                = var.enable_backup
  enable_log_filter            = var.enable_log_filter
  enable_auto_startstop        = var.enable_auto_startstop
  start_time                   = lookup(each.value, "start_time", "07:00")
  stop_time                    = lookup(each.value, "stop_time", "00:01")
  timezone                     = var.timezone

  location                     = var.location
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id
  log_analytics_workspace_workspace_id = azurerm_log_analytics_workspace.monitor.workspace_id
  log_analytics_workspace_workspace_key = azurerm_log_analytics_workspace.monitor.primary_shared_key

  minecraft_ops                = var.minecraft_ops
  minecraft_server_port        = lookup(each.value, "minecraft_server_port", 25565)
  minecraft_timezone           = var.minecraft_timezone
  minecraft_users              = var.minecraft_users

  monitor_action_group_id      = azurerm_monitor_action_group.arm_roles.id

  recovery_vault_name          = var.enable_backup ? azurerm_recovery_services_vault.backup.0.name : null

  resource_group_id            = azurerm_resource_group.minecraft.id
  resource_group_name          = azurerm_resource_group.minecraft.name
  storage_account_name         = azurerm_storage_account.minecraft.name
  storage_account_key          = azurerm_storage_account.minecraft.primary_access_key
  tags                         = azurerm_resource_group.minecraft.tags
  vanity_dns_zone_id           = var.vanity_dns_zone_id
  vanity_hostname_prefix       = lookup(each.value, "vanity_hostname_prefix", "minecraft")

  workflow_sp_application_id   = local.workflow_sp_application_id
  workflow_sp_application_secret= local.workflow_sp_application_secret
  workflow_sp_object_id        = local.workflow_sp_object_id

  depends_on                   = [
    # azurerm_backup_container_storage_account.minecraft,
    azurerm_role_assignment.terraform_storage_owner
  ]

  for_each                     = var.minecraft_config
}

module functions {
  source                       = "./modules/functions"
  appinsights_id               = azurerm_application_insights.insights.id
  appinsights_instrumentation_key = azurerm_application_insights.insights.instrumentation_key
  location                     = var.location
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.monitor.id
  minecraft_fqdn               = module.minecraft[each.key].minecraft_server_fqdn
  minecraft_port               = lookup(each.value, "minecraft_server_port", 25565)
  plan_name                    = replace("${azurerm_resource_group.minecraft.name}-${each.key}-functions","-primary","")
  resource_group_name          = azurerm_resource_group.minecraft.name
  suffix                       = local.suffix

  for_each                     = var.minecraft_config
}
