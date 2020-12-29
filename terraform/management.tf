resource azurerm_log_analytics_workspace monitor {
  name                         = "${azurerm_resource_group.minecraft.name}-loganalytics"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  sku                          = "Free"
  retention_in_days            = 7

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