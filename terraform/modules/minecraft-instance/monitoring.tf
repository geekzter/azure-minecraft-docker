# Memory > 1.9 GB
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert
resource azurerm_monitor_metric_alert memory {
  name                         = "${var.name}-memory-alert"
  resource_group_name          = var.resource_group_name
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
  frequency                    = "PT5M"
  severity                     = 3
  window_size                  = "PT15M"

  action {
    action_group_id            = var.monitor_action_group_id
  }
}

resource azurerm_monitor_metric_alert memory_dynamic {
  name                         = "${var.name}-memory-dynamic-alert"
  resource_group_name          = var.resource_group_name
  scopes                       = [azurerm_container_group.minecraft_server.id]
  description                  = "Action will be triggered when Memory usage is unusually high"

  dynamic_criteria {
    metric_namespace           = "microsoft.containerinstance/containergroups"
    metric_name                = "MemoryUsage"
    aggregation                = "Average"
    operator                   = "GreaterThan"
    alert_sensitivity          = "Low"

    dimension {
      name                     = "containerName"
      operator                 = "Include"
      values                   = ["minecraft"]
    }
  }
  severity                     = 3

  action {
    action_group_id            = var.monitor_action_group_id
  }
}

resource azurerm_monitor_metric_alert cpu_dynamic {
  name                         = "${var.name}-cpu-dynamic-alert"
  resource_group_name          = var.resource_group_name
  scopes                       = [azurerm_container_group.minecraft_server.id]
  description                  = "Action will be triggered when CPU usage is unusually high"

  dynamic_criteria {
    metric_namespace           = "microsoft.containerinstance/containergroups"
    metric_name                = "CpuUsage"
    aggregation                = "Average"
    operator                   = "GreaterThan"
    alert_sensitivity          = "Low"

    dimension {
      name                     = "containerName"
      operator                 = "Include"
      values                   = ["minecraft"]
    }
  }
  severity                     = 3

  action {
    action_group_id            = var.monitor_action_group_id
  }
}