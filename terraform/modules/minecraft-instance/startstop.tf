locals {
  # TODO: check resource ID when multiple modules are created
  api_id                       = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/aci"
  # connection_name              = "aci-${local.suffix}"
  connection_name              = var.name
  connection_name_json         = replace(local.connection_name,"-","_")
  connection_id                = "${var.resource_group_id}/providers/Microsoft.Web/connections/${local.connection_name}"

  suffix                       = var.tags["suffix"]
}

resource azurerm_role_assignment minecraft_startstop {
  scope                        = azurerm_container_group.minecraft_server.id
  role_definition_name         = "Contributor"
  principal_id                 = var.workflow_sp_object_id

  count                        = var.enable_auto_startstop ? 1 : 0
}

resource azurerm_logic_app_workflow start {
  name                         = "${var.name}-start"
  resource_group_name          = var.resource_group_name
  location                     = var.location

  lifecycle {
    ignore_changes             = [
      parameters
    ]
  }

  count                        = var.enable_auto_startstop && var.start_time != null && var.start_time != "" ? 1 : 0
}  
resource azurerm_monitor_diagnostic_setting start_workflow {
  name                         = "${azurerm_logic_app_workflow.start.0.name}-logs"
  target_resource_id           = azurerm_logic_app_workflow.start.0.id
  log_analytics_workspace_id   = var.log_analytics_workspace_id

  log {
    category                   = "WorkflowRuntime"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 30
    }
  }
  metric {
    category                   = "AllMetrics"

    retention_policy {
      enabled                  = true
      days                     = 30
    }
  }
  count                        = var.enable_auto_startstop && var.start_time != null && var.start_time != "" ? 1 : 0
}

resource azurerm_logic_app_workflow stop {
  name                         = "${var.name}-stop"
  resource_group_name          = var.resource_group_name
  location                     = var.location

  lifecycle {
    ignore_changes             = [
      parameters
    ]
  }

  count                        = var.enable_auto_startstop && var.stop_time != null && var.stop_time != "" ? 1 : 0
}  
resource azurerm_monitor_diagnostic_setting stop_workflow {
  name                         = "${azurerm_logic_app_workflow.stop.0.name}-logs"
  target_resource_id           = azurerm_logic_app_workflow.stop.0.id
  log_analytics_workspace_id   = var.log_analytics_workspace_id

  log {
    category                   = "WorkflowRuntime"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 30
    }
  }
  metric {
    category                   = "AllMetrics"

    retention_policy {
      enabled                  = true
      days                     = 30
    }
  }

  count                        = var.enable_auto_startstop && var.stop_time != null && var.stop_time != "" ? 1 : 0
}
# resource azurerm_logic_app_trigger_recurrence stop_trigger {
#   name                         = "stop"
#   logic_app_id                 = azurerm_logic_app_workflow.stop.0.id
#   frequency                    = "Week"
#   interval                     = 1
#   start_time                   = "${formatdate("YYYY-MM-DD",timestamp())}T${var.start_time}:00"
#   schedule {
#     on_these_days              = [
#       "Monday",
#       "Tuesday", 
#       "Wednesday", 
#       "Thursday", 
#       "Friday",
#     ]
#   }

#   count                        = var.enable_auto_startstop && var.stop_time != null && var.stop_time != "" ? 1 : 0
# }

resource azurerm_resource_group_template_deployment container_instance_api_connection {
  name                         = "${var.name}-aci-connection"
  resource_group_name          = var.resource_group_name
  deployment_mode              = "Incremental"
  template_content             = templatefile("${path.root}/arm/workflow-connection-template.json",
  {
    api_id                     = local.api_id
    connection_name            = local.connection_name
    connection_display_name    = local.connection_name
    client_id                  = var.workflow_sp_application_id
    client_secret              = var.workflow_sp_application_secret
    location                   = var.location       
    tenant_id                  = data.azurerm_subscription.primary.tenant_id
  })

  tags                         = var.tags
  count                        = var.enable_auto_startstop ? 1 : 0

  depends_on                   = [azurerm_role_assignment.minecraft_startstop]                                                                    
}

# HACK: Terraform azurerm provider does not support Logic App definitions, this ia the workaround
#       https://github.com/terraform-providers/terraform-provider-azurerm/issues/5197#issuecomment-601021905
resource azurerm_resource_group_template_deployment start_workflow {
  name                         = "${azurerm_logic_app_workflow.start.0.name}-implementation"
  resource_group_name          = var.resource_group_name
  deployment_mode              = "Incremental"
  template_content             = templatefile("${path.root}/arm/startstop-template.json",
  {
    api_id                     = local.api_id
    connection_id              = local.connection_id
    connection_name            = local.connection_name
    connection_name_json       = local.connection_name_json
    container_group_operation  = "${azurerm_container_group.minecraft_server.id}/start"
    container_group_id         = azurerm_container_group.minecraft_server.id
    location                   = var.location
    operation                  = "start"
    start_time                 = "${formatdate("YYYY-MM-DD",timestamp())}T${var.start_time}"
    time_zone                  = var.timezone
    workflow_name              = azurerm_logic_app_workflow.start.0.name
  })

  tags                         = var.tags
  count                        = var.enable_auto_startstop && var.start_time != null && var.start_time != "" ? 1 : 0

  depends_on                   = [azurerm_resource_group_template_deployment.container_instance_api_connection]
}

resource azurerm_resource_group_template_deployment stop_workflow {
  name                         = "${azurerm_logic_app_workflow.stop.0.name}-implementation"
  resource_group_name          = var.resource_group_name
  deployment_mode              = "Incremental"
  template_content             = templatefile("${path.root}/arm/startstop-template.json",
  {
    api_id                     = local.api_id
    connection_id              = local.connection_id
    connection_name            = local.connection_name
    connection_name_json       = local.connection_name_json
    container_group_id         = azurerm_container_group.minecraft_server.id
    location                   = var.location       
    operation                  = "stop"
    start_time                 = "${formatdate("YYYY-MM-DD",timestamp())}T${var.stop_time}"
    time_zone                  = var.timezone
    workflow_name              = azurerm_logic_app_workflow.stop.0.name
  })

  tags                         = var.tags
  count                        = var.enable_auto_startstop && var.stop_time != null && var.stop_time != "" ? 1 : 0

  depends_on                   = [
    azurerm_resource_group_template_deployment.container_instance_api_connection,
    # azurerm_logic_app_trigger_recurrence.stop_trigger
  ]
}