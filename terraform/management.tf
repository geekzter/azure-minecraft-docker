resource azurerm_log_analytics_workspace monitor {
  name                         = "${azurerm_resource_group.minecraft.name}-loganalytics"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  sku                          = "PerGB2018"
  retention_in_days            = 30

  tags                         = local.tags
}

resource azurerm_log_analytics_solution log_analytics_solution {
  solution_name                = "ContainerInsights" 
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  workspace_resource_id        = azurerm_log_analytics_workspace.monitor.id
  workspace_name               = azurerm_log_analytics_workspace.monitor.name

  plan {
    publisher                  = "Microsoft"
    product                    = "OMSGallery/ContainerInsights"
  }
} 

resource azurerm_dashboard minecraft_dashboard {
  name                         = "${azurerm_resource_group.minecraft.name}-dashboard"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  dashboard_properties         = templatefile("dashboard.tpl",merge(
    local.tags,
    {
      environment              = local.environment
      location                 = azurerm_resource_group.minecraft.location
      minecraft_server_fqdn    = local.minecraft_server_fqdn
      resource_group           = azurerm_resource_group.minecraft.name
      resource_group_id        = azurerm_resource_group.minecraft.id
      subscription_id          = data.azurerm_subscription.primary.id
      subscription_guid        = data.azurerm_subscription.primary.subscription_id
      suffix                   = local.suffix
      workspace                = terraform.workspace
  }))

  tags                         = merge(
    local.tags,
    map(
      "hidden-title",           "Minecraft (${local.environment})",
    )
  )
}

resource azurerm_logic_app_workflow shutdown {
  name                         = "${azurerm_resource_group.minecraft.name}-shutdown"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location

  # lifecycle {
  #   ignore_changes             = [
  #       "parameters.$connections"
  #   ]
  # }
}  

resource azurerm_template_deployment container_instance_api_connection {
  name                         = "${azurerm_logic_app_workflow.shutdown.name}-connection"
  resource_group_name          = azurerm_resource_group.minecraft.name
  deployment_mode              = "Incremental"
  template_body                = file("${path.root}/arm/workflow-connection.json")
  parameters                   = {                                    
    "api_id"                   = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.minecraft.location}/managedApis/aci"
    "connection_name"          = "${azurerm_logic_app_workflow.shutdown.name}-connection"
    "client_id"                = local.workflow_sp_application_id
    "client_secret"            = local.workflow_sp_application_secret
    "location"                 = azurerm_resource_group.minecraft.location       
    "tenant_id"                = data.azurerm_subscription.primary.tenant_id
  }                                                                                                                                          
}
