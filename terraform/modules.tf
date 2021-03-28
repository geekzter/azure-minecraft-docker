# Provision base network infrastructure
module service_principal {
  source                       = "./modules/service-principal"
  name                         = "workflow-${terraform.workspace}-${local.suffix}"

  count                        = local.create_service_principal ? 1 : 0
}

module functions {
  source                       = "./modules/functions"
  appinsights_id               = azurerm_application_insights.insights.id
  appinsights_instrumentation_key = azurerm_application_insights.insights.instrumentation_key
  location                     = var.location
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.monitor.id
  minecraft_fqdn               = local.minecraft_server_fqdn
  minecraft_port               = local.minecraft_server_port
  resource_group_name          = azurerm_resource_group.minecraft.name
  suffix                       = local.suffix
}