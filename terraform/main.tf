data azurerm_client_config current {}

# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

locals {
  environment                  = replace(terraform.workspace,"default","dev")
  # https://github.com/itzg/docker-minecraft-server
  container_image              = var.container_image_tag != null && var.container_image_tag != "" ? "itzg/minecraft-server:${var.container_image_tag}" : "itzg/minecraft-server"
  minecraft_server_fqdn        = var.vanity_dns_zone_id != "" ? replace(try(azurerm_dns_cname_record.vanity_hostname.0.fqdn,""),"/\\W*$/","") : azurerm_container_group.minecraft_server.fqdn
  minecraft_server_port        = 25565
  # subscription_guid            = split("/",azurerm_resource_group.minecraft.id)[1]
  suffix                       = random_string.suffix.result
  tags                         = merge(
    map(
      "application",             "Minecraft",
      "environment",             local.environment,
      "provisioner",             "terraform",
      "repository" ,             "azure-minecraft-docker",
      "run-id",                  var.run_id,
      "suffix",                  local.suffix,
      "workspace",               terraform.workspace,
    )
  )

  config                       = merge(
    local.tags,
    map(
      "container_group_id",      azurerm_container_group.minecraft_server.id,
      "container_image_digest",  data.docker_registry_image.minecraft.sha256_digest,
      "minecraft_allow_nether",  tostring(var.minecraft_allow_nether),
      "minecraft_announce_player_achievements", tostring(var.minecraft_announce_player_achievements),
      "minecraft_enable_command_blocks", tostring(var.minecraft_enable_command_blocks),
      "minecraft_ops",           join(",",var.minecraft_ops),
      "minecraft_type",          var.minecraft_type,
      "minecraft_version",       var.minecraft_version,
      "vanity_dns_zone_id",      var.vanity_dns_zone_id,
      "vanity_hostname_prefix",  var.vanity_hostname_prefix,
    )
  )

  lifecycle                    = {
    ignore_changes             = ["tags"]
  }
}

resource azurerm_resource_group minecraft {
  name                         = "Minecraft-${terraform.workspace}-${local.suffix}"
  location                     = var.location

  tags                         = local.tags
}

# Requires Terraform owner access to resource group, in order to be able to perform access management
resource azurerm_role_assignment contributor {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Contributor"
  principal_id                 = each.value

  for_each                     = toset(var.resource_group_contributors)
}
resource azurerm_role_assignment readers {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Reader"
  principal_id                 = each.value

  for_each                     = toset(var.resource_group_readers)
}

resource azurerm_container_group minecraft_server {
  name                         = "Minecraft-${local.suffix}"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  ip_address_type              = "public"
  dns_name_label               = "minecraft-${terraform.workspace}-${local.suffix}"
  os_type                      = "linux"

  container {
    cpu                        = "1"
    name                       = "minecraft"
    environment_variables = {
      "ALLOW_NETHER"           = var.minecraft_allow_nether
      "ANNOUNCE_PLAYER_ACHIEVEMENTS" = var.minecraft_announce_player_achievements
      "DIFFICULTY"             = var.minecraft_difficulty
      "ENABLE_COMMAND_BLOCK"   = var.minecraft_enable_command_blocks
      "EULA"                   = "true"
      "MAX_PLAYERS"            = var.minecraft_max_players
      "MODS"                   = join(",",var.minecraft_mods)
      "MODE"                   = var.minecraft_mode
      "MOTD"                   = var.minecraft_motd
      "OPS"                    = join(",",var.minecraft_ops)
      "SNOOPER_ENABLED"        = var.minecraft_snooper_enabled
      "TYPE"                   = var.minecraft_type
      "TZ"                     = var.minecraft_timezone
      "VERSION"                = var.minecraft_version
      "WHITELIST"              = join(",",var.minecraft_users)
    }
    image                      = local.container_image
    memory                     = "2"
    ports {
      port                     = 80
      protocol                 = "TCP"
    }
    ports {
      port                     = local.minecraft_server_port
      protocol                 = "TCP"
    }
    volume {
      mount_path               = "/data"
      name                     = "azurefile"
      read_only                = false
      share_name               = azurerm_storage_share.minecraft_share.name
      storage_account_name     = azurerm_storage_account.minecraft.name
      storage_account_key      = azurerm_storage_account.minecraft.primary_access_key
    }
    volume {
      mount_path               = "/modpacks"
      name                     = "modpacks"
      read_only                = false
      share_name               = azurerm_storage_share.minecraft_modpacks.name
      storage_account_name     = azurerm_storage_account.minecraft.name
      storage_account_key      = azurerm_storage_account.minecraft.primary_access_key
    }
  }

  diagnostics {
    log_analytics {
      workspace_id             = azurerm_log_analytics_workspace.monitor.workspace_id
      workspace_key            = azurerm_log_analytics_workspace.monitor.primary_shared_key
    }
  }

  tags                         = local.tags

  depends_on                   = [
    azurerm_log_analytics_solution.log_analytics_solution
  ]
}

data docker_registry_image minecraft {
  name                         = azurerm_container_group.minecraft_server.container.0.image
}

resource null_resource minecraft_server_log {
  triggers = {
    always                     = timestamp()
  }

  provisioner local-exec {
    command                    = "az container logs --ids ${azurerm_container_group.minecraft_server.id}"
  }
}

data azurerm_dns_zone vanity_domain {
  name                         = element(split("/",var.vanity_dns_zone_id),length(split("/",var.vanity_dns_zone_id))-1)
  resource_group_name          = element(split("/",var.vanity_dns_zone_id),length(split("/",var.vanity_dns_zone_id))-5)

  count                        = var.vanity_dns_zone_id != "" ? 1 : 0
}

resource azurerm_dns_cname_record vanity_hostname {
  name                         = "${var.vanity_hostname_prefix}${replace(local.environment,"prod","")}"
  zone_name                    = data.azurerm_dns_zone.vanity_domain.0.name
  resource_group_name          = data.azurerm_dns_zone.vanity_domain.0.resource_group_name
  ttl                          = 300
  record                       = azurerm_container_group.minecraft_server.fqdn

  tags                         = local.tags
  count                        = var.vanity_dns_zone_id != "" ? 1 : 0
}