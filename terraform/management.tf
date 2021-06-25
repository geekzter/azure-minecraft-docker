resource azurerm_log_analytics_workspace monitor {
  name                         = "${azurerm_resource_group.minecraft.name}-loganalytics"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  sku                          = "PerGB2018"
  retention_in_days            = 30

  tags                         = local.tags
}

resource azurerm_application_insights insights {
  name                         = "${azurerm_log_analytics_workspace.monitor.resource_group_name}-insights"
  location                     = azurerm_log_analytics_workspace.monitor.location
  resource_group_name          = azurerm_log_analytics_workspace.monitor.resource_group_name
  application_type             = "web"

  # Associate with Log Analytics workspace
  provisioner local-exec {
    command                    = "az monitor app-insights component update --ids ${self.id} --workspace ${azurerm_log_analytics_workspace.monitor.id}"
    environment                = {
      AZURE_EXTENSION_USE_DYNAMIC_INSTALL = "yes_without_prompt"
    }  
  }
  tags                         = azurerm_resource_group.minecraft.tags
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
      minecraft_server_fqdn    = join(" ",[for minecraft in module.minecraft : minecraft.minecraft_server_fqdn])
      resource_group           = azurerm_resource_group.minecraft.name
      resource_group_id        = azurerm_resource_group.minecraft.id
      subscription_id          = data.azurerm_subscription.primary.id
      subscription_guid        = data.azurerm_subscription.primary.subscription_id
      suffix                   = local.suffix
      workspace                = terraform.workspace
  }))

  tags                         = merge(
    local.tags,
    {
      hidden-title             = "Minecraft (${local.environment})"
    }
  )
}

locals {
  create_service_principal     = (var.workflow_sp_application_id == "" || var.workflow_sp_object_id == "" || var.workflow_sp_application_secret == "") ? true : false  
  workflow_sp_application_id   = local.create_service_principal ? module.service_principal.0.application_id : var.workflow_sp_application_id
  workflow_sp_application_secret= local.create_service_principal ? module.service_principal.0.secret : var.workflow_sp_application_secret
  workflow_sp_object_id        = local.create_service_principal ? module.service_principal.0.object_id : var.workflow_sp_object_id
}

data azurerm_role_definition contributor {
  name                         = "Contributor"
}
data azurerm_role_definition reader {
  name                         = "Reader"
}

resource azurerm_monitor_action_group arm_roles {
  name                         = "${azurerm_resource_group.minecraft.name}-arm-alert-group"
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

resource azurerm_monitor_action_group push_provisioner {
  name                         = "${azurerm_resource_group.minecraft.name}-push-alert-group"
  resource_group_name          = azurerm_resource_group.minecraft.name
  short_name                   = "provisioner"

  azure_app_push_receiver {
    name                       = "provisioner"
    email_address              = var.provisoner_email_address
  }

  count                        = var.provisoner_email_address != "" ? 1 : 0
}

resource azurerm_monitor_scheduled_query_rules_alert container_failed_alert {
  name                         = "${azurerm_resource_group.minecraft.name}-container-failed-alert"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location

  action {
    action_group               = [azurerm_monitor_action_group.arm_roles.id]
    email_subject              = "Minecraft container failed"
  }
  data_source_id               = azurerm_log_analytics_workspace.monitor.id
  description                  = "Alert when Mincraft container fails"
  enabled                      = true
  query                        = templatefile("${path.root}/../kusto/container-failed.csl", { 
    resource_group_name        = azurerm_resource_group.minecraft.name
  })  
  severity                     = 2
  frequency                    = 5
  time_window                  = 5
  trigger {
    operator                   = "GreaterThan"
    threshold                  = 0
  }
}
locals {
  all_action_groups            = var.provisoner_email_address != "" ? [
      azurerm_monitor_action_group.arm_roles.id,
      azurerm_monitor_action_group.push_provisioner.0.id,
    ] : [
      azurerm_monitor_action_group.arm_roles.id,
    ]
}
resource azurerm_monitor_scheduled_query_rules_alert container_inaccessible_alert {
  name                         = "${azurerm_resource_group.minecraft.name}-${each.key}-inaccessible-alert"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location

  action {
    action_group               = local.all_action_groups
    email_subject              = "Minecraft container inaccessible"
  }
  data_source_id               = azurerm_log_analytics_workspace.monitor.id
  description                  = "Alert when Mincraft container is running but can't be connected to"
  enabled                      = true
  query                        = templatefile("${path.root}/../kusto/container-inaccessible.csl", { 
    container_group_name       = module.minecraft[each.key].container_group_name
    function_name              = module.functions[each.key].function_name
  })  
  severity                     = 1
  frequency                    = 5
  time_window                  = 2880 # Window defined in query, subquery requires no constraint
  # throttling                   = 30
  trigger {
    operator                   = "GreaterThan"
    threshold                  = 2
  }

  for_each                     = var.minecraft_config
}
resource azurerm_monitor_scheduled_query_rules_alert custom_alert {
  name                         = "${azurerm_resource_group.minecraft.name}-custom-alert"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location

  action {
    action_group               = local.all_action_groups
    email_subject              = var.custom_alert_subject != "" ? var.custom_alert_subject : "Custom alert"
  }
  data_source_id               = azurerm_log_analytics_workspace.monitor.id
  description                  = "Custom alert"
  enabled                      = var.custom_alert_enabled
  query                        = var.custom_alert_query
  severity                     = 1
  frequency                    = 5
  time_window                  = 5
  # throttling                   = 30
  trigger {
    operator                   = "GreaterThan"
    threshold                  = 0
  }
  count                        = var.custom_alert_query != "" ? 1 : 0
}