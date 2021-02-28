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

locals {
  api_id                       = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.minecraft.location}/managedApis/aci"
  # connection_name              = "aci"
  connection_name              = "aci-${local.suffix}"
  connection_name_json         = replace(local.connection_name,"-","_")
  connection_id                = "${azurerm_resource_group.minecraft.id}/providers/Microsoft.Web/connections/${local.connection_name}"
  create_service_principal     = (var.workflow_sp_application_id == "" || var.workflow_sp_object_id == "" || var.workflow_sp_application_secret == "") ? true : false  
  workflow_sp_application_id   = local.create_service_principal ? module.service_principal.0.application_id : var.workflow_sp_application_id
  workflow_sp_application_secret= local.create_service_principal ? module.service_principal.0.secret : var.workflow_sp_application_secret
  workflow_sp_object_id        = local.create_service_principal ? module.service_principal.0.object_id : var.workflow_sp_object_id
}

resource azurerm_role_assignment minecraft_startstop {
  scope                        = azurerm_container_group.minecraft_server.id
  role_definition_name         = "Contributor"
  principal_id                 = local.workflow_sp_object_id

  count                        = var.enable_auto_startstop ? 1 : 0
}

resource azurerm_logic_app_workflow start {
  name                         = "${azurerm_resource_group.minecraft.name}-start"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location

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
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id

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
  name                         = "${azurerm_resource_group.minecraft.name}-stop"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location

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
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id

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

resource azurerm_resource_group_template_deployment container_instance_api_connection {
  name                         = "${azurerm_resource_group.minecraft.name}-aci-connection"
  resource_group_name          = azurerm_resource_group.minecraft.name
  deployment_mode              = "Incremental"
  template_content             = templatefile("${path.root}/arm/workflow-connection-template.json",
  {
    api_id                     = local.api_id
    # connection_name            = "aci"
    connection_name            = local.connection_name
    connection_display_name    = local.connection_name
    client_id                  = local.workflow_sp_application_id
    client_secret              = local.workflow_sp_application_secret
    location                   = azurerm_resource_group.minecraft.location       
    tenant_id                  = data.azurerm_subscription.primary.tenant_id
  })

  count                        = var.enable_auto_startstop ? 1 : 0

  depends_on                   = [azurerm_role_assignment.minecraft_startstop]                                                                    
}

# HACK: Terraform azurerm provider does not support Logic App definitions, this ia the workaround
#       https://github.com/terraform-providers/terraform-provider-azurerm/issues/5197#issuecomment-601021905
resource azurerm_resource_group_template_deployment start_workflow {
  name                         = "${azurerm_logic_app_workflow.start.0.name}-implementation"
  resource_group_name          = azurerm_resource_group.minecraft.name
  deployment_mode              = "Incremental"
  template_content             = templatefile("${path.root}/arm/startstop-template.json",
  {
    api_id                     = local.api_id
    connection_id              = local.connection_id
    connection_name            = local.connection_name
    connection_name_json       = local.connection_name_json
    container_group_operation  = "${azurerm_container_group.minecraft_server.id}/start"
    container_group_id         = azurerm_container_group.minecraft_server.id
    location                   = azurerm_resource_group.minecraft.location
    operation                  = "start"
    start_time                 = "${formatdate("YYYY-MM-DD",timestamp())}T${var.start_time}Z"
    time_zone                  = var.timezone
    workflow_name              = azurerm_logic_app_workflow.start.0.name
  })

  count                        = var.enable_auto_startstop && var.start_time != null && var.start_time != "" ? 1 : 0

  depends_on                   = [azurerm_resource_group_template_deployment.container_instance_api_connection]
}

resource azurerm_resource_group_template_deployment stop_workflow {
  name                         = "${azurerm_logic_app_workflow.stop.0.name}-implementation"
  resource_group_name          = azurerm_resource_group.minecraft.name
  deployment_mode              = "Incremental"
  template_content             = templatefile("${path.root}/arm/startstop-template.json",
  {
    api_id                     = local.api_id
    connection_id              = local.connection_id
    connection_name            = local.connection_name
    connection_name_json       = local.connection_name_json
    container_group_id         = azurerm_container_group.minecraft_server.id
    location                   = azurerm_resource_group.minecraft.location       
    operation                  = "stop"
    start_time                 = "${formatdate("YYYY-MM-DD",timestamp())}T${var.stop_time}Z"
    time_zone                  = var.timezone
    workflow_name              = azurerm_logic_app_workflow.stop.0.name
  })

  count                        = var.enable_auto_startstop && var.stop_time != null && var.stop_time != "" ? 1 : 0

  depends_on                   = [azurerm_resource_group_template_deployment.container_instance_api_connection]
}

data azurerm_role_definition contributor {
  name                         = "Contributor"
}
data azurerm_role_definition reader {
  name                         = "Reader"
}

resource azurerm_monitor_action_group arm_roles {
  name                         = "${azurerm_resource_group.minecraft.name}-alert-group"
  resource_group_name          = azurerm_resource_group.minecraft.name
  short_name                   = "arm-roles"

  arm_role_receiver {
    name                       = data.azurerm_role_definition.contributor.name
    role_id                    = split("/",data.azurerm_role_definition.contributor.id)[4]
    use_common_alert_schema    = true
  }

  arm_role_receiver {
    name                       = data.azurerm_role_definition.reader.name
    role_id                    = split("/",data.azurerm_role_definition.reader.id)[4]
    use_common_alert_schema    = true
  }
}

# Memory > 1.9 GB
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert
resource azurerm_monitor_metric_alert memory {
  name                         = "${azurerm_resource_group.minecraft.name}-memory-alert"
  resource_group_name          = azurerm_resource_group.minecraft.name
  scopes                       = [azurerm_container_group.minecraft_server.id]
  description                  = "Action will be triggered when Memory usage is greater than 1.9 GB"

  criteria {
    metric_namespace           = "microsoft.containerinstance/containergroups"
    metric_name                = "MemoryUsage"
    aggregation                = "Average"
    operator                   = "GreaterThan"
    threshold                  = 1900000000 # 1.9 GB

    dimension {
      name                     = "containerName"
      operator                 = "Include"
      values                   = ["minecraft"]
    }
  }

  action {
    action_group_id            = azurerm_monitor_action_group.arm_roles.id
  }
}
resource azurerm_monitor_metric_alert cpu {
  name                         = "${azurerm_resource_group.minecraft.name}-cpu-alert"
  resource_group_name          = azurerm_resource_group.minecraft.name
  scopes                       = [azurerm_container_group.minecraft_server.id]
  description                  = "Action will be triggered when CPU usage is greater than 975 millicores"

  criteria {
    metric_namespace           = "microsoft.containerinstance/containergroups"
    metric_name                = "CpuUsage"
    aggregation                = "Average"
    operator                   = "GreaterThan"
    threshold                  = 975 # 975 millicores = 97.5% of 1 core

    dimension {
      name                     = "containerName"
      operator                 = "Include"
      values                   = ["minecraft"]
    }
  }

  action {
    action_group_id            = azurerm_monitor_action_group.arm_roles.id
  }
}
resource azurerm_monitor_metric_alert cpu_dynamic {
  name                         = "${azurerm_resource_group.minecraft.name}-cpu-dynamic-alert"
  resource_group_name          = azurerm_resource_group.minecraft.name
  scopes                       = [azurerm_container_group.minecraft_server.id]
  description                  = "Action will be triggered when CPU usage is unusually high"

  dynamic_criteria {
    metric_namespace           = "microsoft.containerinstance/containergroups"
    metric_name                = "CpuUsage"
    aggregation                = "Average"
    operator                   = "GreaterThan"
    alert_sensitivity          = "Medium"

    dimension {
      name                     = "containerName"
      operator                 = "Include"
      values                   = ["minecraft"]
    }
  }

  action {
    action_group_id            = azurerm_monitor_action_group.arm_roles.id
  }
}