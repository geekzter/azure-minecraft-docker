data azurerm_resource_group rg {
  name                         = var.resource_group_name
}

locals {
  app_service_settings         = {
    APPINSIGHTS_INSTRUMENTATIONKEY = var.appinsights_instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = "InstrumentationKey=${var.appinsights_instrumentation_key}"
    FUNCTIONS_WORKER_RUNTIME   = "dotnet"
    # WEBSITE_CONTENTSHARE       = "${var.resource_group_name}-ping-test-content"
    # WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.functions.name};AccountKey=${azurerm_storage_account.functions.primary_access_key};EndpointSuffix=core.windows.net"
  }
}

resource azurerm_storage_account functions {
  # name                         = "${lower(substr(replace(var.resource_group_name,"/a|e|i|o|u|y|-/",""),0,17))}fnc${var.suffix}"
  name                         = "min${lower(substr(replace(var.location,"/a|e|i|o|u|y|-/",""),0,13))}func${var.suffix}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
}
resource azurerm_app_service_plan functions {
  name                         = "${var.resource_group_name}-${var.location}-functions"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  kind                         = "FunctionApp"
  reserved                     = true

  sku {
    tier                       = "Dynamic"
    size                       = "Y1"
  }

  lifecycle {
    ignore_changes             = [
      kind
    ]
  }

  tags                         = data.azurerm_resource_group.rg.tags
}
resource azurerm_function_app ping_test {
  name                         = "${azurerm_app_service_plan.functions.name}-ping-test"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  app_service_plan_id          = azurerm_app_service_plan.functions.id
  app_settings                 = local.app_service_settings
  storage_account_name         = azurerm_storage_account.functions.name
  storage_account_access_key   = azurerm_storage_account.functions.primary_access_key
  version                      = "~3"

  lifecycle {
    ignore_changes             = [
      # Ignore Visual Studio Code modifications
                                 app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"], 
                                 app_settings["WEBSITE_CONTENTSHARE"], 
                                 os_type
    ]
  }  

  tags                         = data.azurerm_resource_group.rg.tags
}
# resource azurerm_monitor_scheduled_query_rules_alert ping_test_alert {
#   name                         = "${azurerm_function_app.ping_test.name}-alert"
#   resource_group_name          = var.resource_group_name
#   location                     = data.azurerm_resource_group.rg.location

#   action {
#     action_group               = [var.monitor_action_group_id]
#     email_subject              = "Synapse test query from ${data.azurerm_resource_group.rg.location} is taking longer than expected"
#   }
#   data_source_id               = var.log_analytics_workspace_resource_id
#   description                  = "Alert when # low performing queries goes over threshold"
#   enabled                      = false
#   query                        = templatefile("${path.root}/../kusto/alert.kql", { 
#     function_name              = azurerm_function_app.ping_test.name
#   })  
#   severity                     = 2
#   frequency                    = 5
#   time_window                  = 30
#   trigger {
#     operator                   = "GreaterThan"
#     threshold                  = 2
#   }
# }
resource azurerm_monitor_diagnostic_setting function_logs {
  name                         = "Function_Logs"
  target_resource_id           = azurerm_function_app.ping_test.id
  log_analytics_workspace_id   = var.log_analytics_workspace_resource_id

  log {
    category                   = "FunctionAppLogs"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }
  metric {
    category                   = "AllMetrics"

    retention_policy {
      enabled                  = false
    }
  }
}
