# Provision base network infrastructure
module service_principal {
  source                       = "./modules/service-principal"
  name                         = "workflow-${terraform.workspace}-${local.suffix}"

  count                        = local.create_service_principal ? 1 : 0
}

module minecraft {
  source                       = "./modules/minecraft-instance"
  name                         = "${azurerm_resource_group.minecraft.name}-minecraft"
  # name                         = "minecraft-${terraform.workspace}-${local.suffix}"

  configuration_storage_container_name= azurerm_storage_container.configuration.name

  container_image_tag          = var.container_image_tag
  container_data_share_name    = "minecraft-aci-data-${local.suffix}"
  container_modpacks_share_name= "minecraft-aci-modpacks-${local.suffix}"
  environment_variables        = var.minecraft_environment_variables

  environment                  = local.environment

  enable_log_filter            = var.enable_log_filter
  enable_auto_startstop        = var.enable_auto_startstop
  start_time                   = var.start_time
  stop_time                    = var.stop_time
  timezone                     = var.timezone

  location                     = var.location
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id
  log_analytics_workspace_workspace_id = azurerm_log_analytics_workspace.monitor.workspace_id
  log_analytics_workspace_workspace_key = azurerm_log_analytics_workspace.monitor.primary_shared_key

  minecraft_ops                = var.minecraft_ops
  minecraft_server_port        = 25565
  minecraft_timezone           = var.minecraft_timezone
  minecraft_users              = var.minecraft_users

  resource_group_id            = azurerm_resource_group.minecraft.id
  resource_group_name          = azurerm_resource_group.minecraft.name
  storage_account_name         = azurerm_storage_account.minecraft.name
  storage_account_key          = azurerm_storage_account.minecraft.primary_access_key
  tags                         = azurerm_resource_group.minecraft.tags
  vanity_dns_zone_id           = var.vanity_dns_zone_id
  vanity_hostname_prefix       = var.vanity_hostname_prefix

  workflow_sp_application_id   = local.workflow_sp_application_id
  workflow_sp_application_secret= local.workflow_sp_application_secret
  workflow_sp_object_id        = local.workflow_sp_object_id

  depends_on                   = [azurerm_role_assignment.terraform_storage_owner]
}

module functions {
  source                       = "./modules/functions"
  appinsights_id               = azurerm_application_insights.insights.id
  appinsights_instrumentation_key = azurerm_application_insights.insights.instrumentation_key
  location                     = var.location
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.monitor.id
  minecraft_fqdn               = module.minecraft.minecraft_server_fqdn
  minecraft_port               = module.minecraft.minecraft_server_port
  resource_group_name          = azurerm_resource_group.minecraft.name
  suffix                       = local.suffix
}

# module minecraft_duplicate_test {
#   source                       = "./modules/minecraft-instance"
#   name                         = "${azurerm_resource_group.minecraft.name}-minecraft-e"
#   # name                         = "minecraft-${terraform.workspace}-${local.suffix}"

#   configuration_storage_container_name= azurerm_storage_container.configuration.name

#   container_image_tag          = var.container_image_tag
#   container_data_share_id      = azurerm_storage_share.minecraft_share2.id
#   container_data_share_name    = azurerm_storage_share.minecraft_share2.name
#   container_modpacks_share_name= azurerm_storage_share.minecraft_modpacks2.name
#   environment_variables        = var.minecraft_environment_variables

#   environment                  = local.environment

#   enable_log_filter            = var.enable_log_filter
#   enable_auto_startstop        = var.enable_auto_startstop
#   start_time                   = var.start_time
#   stop_time                    = var.stop_time
#   timezone                     = var.timezone

#   location                     = var.location
#   log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id
#   log_analytics_workspace_workspace_id = azurerm_log_analytics_workspace.monitor.workspace_id
#   log_analytics_workspace_workspace_key = azurerm_log_analytics_workspace.monitor.primary_shared_key

#   minecraft_ops                = var.minecraft_ops
#   minecraft_server_port        = 25565
#   minecraft_timezone           = var.minecraft_timezone
#   minecraft_users              = var.minecraft_users

#   resource_group_id            = azurerm_resource_group.minecraft.id
#   resource_group_name          = azurerm_resource_group.minecraft.name
#   storage_account_name         = azurerm_storage_account.minecraft.name
#   storage_account_key          = azurerm_storage_account.minecraft.primary_access_key
#   tags                         = azurerm_resource_group.minecraft.tags
#   vanity_dns_zone_id           = var.vanity_dns_zone_id
#   vanity_hostname_prefix       = "test"

#   workflow_sp_application_id   = local.workflow_sp_application_id
#   workflow_sp_application_secret= local.workflow_sp_application_secret
#   workflow_sp_object_id        = local.workflow_sp_object_id

#   depends_on                   = [azurerm_role_assignment.terraform_storage_owner]
# }