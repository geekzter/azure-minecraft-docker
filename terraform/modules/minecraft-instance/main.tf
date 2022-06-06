data azurerm_subscription primary {}

locals {
  config                       = merge(
    var.tags,
    {
      container_group_id       = azurerm_container_group.minecraft_server.id
      minecraft_ops            = join(",",var.minecraft_ops)
      minecraft_users          = join(",",var.minecraft_users)
      vanity_dns_zone_id       = var.vanity_dns_zone_id
      vanity_hostname_prefix   = var.vanity_hostname_prefix
    }
  )

  environment_variables        = merge(
    var.environment_variables,
    {
      OPS                      = join(",",var.minecraft_ops)
      TZ                       = var.minecraft_timezone
      WHITELIST                = var.allow_ops_only ? join(",",var.minecraft_ops) : join(",",var.minecraft_users)
    }
  )  
  # https://github.com/itzg/docker-minecraft-server
  container_image              = var.container_image_tag != null && var.container_image_tag != "" ? "${var.container_image}:${var.container_image_tag}" : var.container_image
  minecraft_server_fqdn        = var.vanity_dns_zone_id != "" ? replace(try(azurerm_dns_cname_record.vanity_hostname.0.fqdn,""),"/\\W*$/","") : azurerm_container_group.minecraft_server.fqdn

  tags                         = merge(
    var.tags,
    {
      vanity-fqdn              = var.vanity_dns_zone_id != "" ? "${var.vanity_hostname_prefix}${replace(var.environment,"prod","")}.${split("/",var.vanity_dns_zone_id)[8]}" : null
    }
  )
}

resource azurerm_container_group minecraft_server {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  ip_address_type              = "Public"
  dns_name_label               = var.name
  os_type                      = "Linux"

  container {
    cpu                        = "1"
    name                       = "minecraft"
    environment_variables      = local.environment_variables
    image                      = local.container_image
    liveness_probe {
      exec                     = [
        "/bin/bash",
        "-c",
        "/health.sh",
      ]
      failure_threshold        = 3
      initial_delay_seconds    = 300
      period_seconds           = 10 # 300
      success_threshold        = 1
      timeout_seconds          = 10
    }
    memory                     = "2"
    ports {
      port                     = 80
      protocol                 = "TCP"
    }
    ports {
      port                     = var.minecraft_server_port
      protocol                 = "TCP"
    }
    volume {
      mount_path               = "/data"
      name                     = "azurefile"
      read_only                = false
      share_name               = azurerm_storage_share.minecraft_share.name
      storage_account_name     = var.storage_account_name
      storage_account_key      = var.storage_account_key
    }
    volume {
      mount_path               = "/modpacks"
      name                     = "modpacks"
      read_only                = false
      share_name               = azurerm_storage_share.minecraft_modpacks.name
      storage_account_name     = var.storage_account_name
      storage_account_key      = var.storage_account_key
    }
  }
  
  diagnostics {
    log_analytics {
      workspace_id             = var.log_analytics_workspace_workspace_id
      workspace_key            = var.log_analytics_workspace_workspace_key
    }
  }

  identity {
    type                       = "UserAssigned"
    identity_ids               = [var.user_assigned_identity_id]
  }

  tags                         = local.tags

  depends_on                   = [
    azurerm_storage_share_file.log_filter_config,
    azurerm_storage_share_file.log_filter_jar,
  ]
}

data azurerm_dns_zone vanity_domain {
  name                         = element(split("/",var.vanity_dns_zone_id),length(split("/",var.vanity_dns_zone_id))-1)
  resource_group_name          = element(split("/",var.vanity_dns_zone_id),length(split("/",var.vanity_dns_zone_id))-5)

  count                        = var.vanity_dns_zone_id != "" ? 1 : 0
}

resource azurerm_dns_cname_record vanity_hostname {
  name                         = "${var.vanity_hostname_prefix}${replace(var.environment,"prod","")}"
  zone_name                    = data.azurerm_dns_zone.vanity_domain.0.name
  resource_group_name          = data.azurerm_dns_zone.vanity_domain.0.resource_group_name
  ttl                          = 300
  record                       = azurerm_container_group.minecraft_server.fqdn

  tags                         = local.tags
  count                        = var.vanity_dns_zone_id != "" ? 1 : 0
}