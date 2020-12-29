resource azurerm_log_analytics_workspace monitor {
  name                         = "${azurerm_resource_group.minecraft.name}-loganalytics"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  sku                          = var.log_analytics_tier
  retention_in_days            = var.log_analytics_tier == "Free" || var.log_analytics_tier == "free" ? 7 : 30
  # daily_quota_gb               = var.log_analytics_tier == "Free" || var.log_analytics_tier == "free" ? 0.5 : -1

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