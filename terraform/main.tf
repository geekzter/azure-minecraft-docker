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
  environment                  = replace(replace(terraform.workspace,"default","dev"),"prod","")
  minecraft_server_port        = 25565
  suffix                       = random_string.suffix.result
  tags                         = merge(
    map(
      "application",             "Minecraft",
      "environment",             local.environment,
      "provisioner",             "terraform",
      "repository" ,             "azure-minecraft-docker",
      "suffix",                  local.suffix,
      "workspace",               terraform.workspace,
    )
  )

  config                       = merge(
    local.tags,
    map(
      "minecraft_enable_command_blocks", tostring(var.minecraft_enable_command_blocks),
      "minecraft_ops",           var.minecraft_ops[0],
      "minecraft_type",          var.minecraft_type,
      # "minecraft_users",         var.minecraft_users,
      "minecraft_version",       var.minecraft_version,
      "vanity_dns_zone_id",      var.vanity_dns_zone_id,
      "vanity_hostname_prefix",  var.vanity_hostname_prefix,
    )
  )

  config_directory             = formatdate("YYYYMMDDhhmm",timestamp())
  # config_directory             = "${formatdate("YYYY",timestamp())}/${formatdate("MM",timestamp())}/${formatdate("DD",timestamp())}/${formatdate("YYYYMMDDhhmm",timestamp())}"

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

resource azurerm_storage_account minecraft {
  name                         = "minecraftstor${local.suffix}"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  account_tier                 = "Standard"
  account_replication_type     = "LRS"

  blob_properties {
    delete_retention_policy {
      days                     = 365
    }
  }

  tags                         = local.tags
}

resource azurerm_storage_share minecraft_share {
  name                         = "minecraft-aci-data-${local.suffix}"
  storage_account_name         = azurerm_storage_account.minecraft.name
  quota                        = 50
}

resource azurerm_storage_share minecraft_modpacks {
  name                         = "minecraft-aci-modpacks-${local.suffix}"
  storage_account_name         = azurerm_storage_account.minecraft.name
  quota                        = 50
}

resource azurerm_storage_container configuration {
  name                         = "configuration"
  storage_account_name         = azurerm_storage_account.minecraft.name
  container_access_type        = "private"
}

resource azurerm_role_assignment terraform_storage_owner {
  scope                        = azurerm_storage_account.minecraft.id
  role_definition_name         = "Storage Blob Data Contributor"
  principal_id                 = each.value

  for_each                     = toset(var.resource_group_contributors)
}

resource azurerm_storage_blob minecraft_configuration {
  name                         = "${local.config_directory}/config.json"
  storage_account_name         = azurerm_storage_account.minecraft.name
  storage_container_name       = azurerm_storage_container.configuration.name
  type                         = "Block"
  source_content               = jsonencode(local.config)

  depends_on                   = [azurerm_role_assignment.terraform_storage_owner]
}

resource azurerm_storage_blob minecraft_environment {
  name                         = "${local.config_directory}/environment.json"
  storage_account_name         = azurerm_storage_account.minecraft.name
  storage_container_name       = azurerm_storage_container.configuration.name
  type                         = "Block"
  source_content               = jsonencode(azurerm_container_group.minecraft_server.container.0.environment_variables)

  depends_on                   = [azurerm_role_assignment.terraform_storage_owner]
}

resource azurerm_storage_blob minecraft_user_configuration {
  name                         = "${local.config_directory}/users.json"
  storage_account_name         = azurerm_storage_account.minecraft.name
  storage_container_name       = azurerm_storage_container.configuration.name
  type                         = "Block"
  source_content               = jsonencode(var.minecraft_users)

  depends_on                   = [azurerm_role_assignment.terraform_storage_owner]
}

resource azurerm_storage_blob minecraft_auto_vars_configuration {
  name                         = "${local.config_directory}/config.auto.tfvars"
  storage_account_name         = azurerm_storage_account.minecraft.name
  storage_container_name       = azurerm_storage_container.configuration.name
  type                         = "Block"
  source                       = "${path.root}/config.auto.tfvars"

  count                        = fileexists("${path.root}/config.auto.tfvars") ? 1 : 0
  depends_on                   = [azurerm_role_assignment.terraform_storage_owner]
}

resource azurerm_management_lock minecraft_data_lock {
  name                         = "${azurerm_storage_account.minecraft.name}-lock"
  scope                        = azurerm_storage_account.minecraft.id
  lock_level                   = "CanNotDelete"
  notes                        = "Do not accidentally delete Minecraft (world) data"

  depends_on                   = [
    azurerm_storage_share.minecraft_share,
    azurerm_storage_share.minecraft_modpacks,
  ]
}

resource azurerm_container_group minecraft_server {
  name                         = "minecraft-${local.suffix}"
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
      "ENABLE_COMMAND_BLOCK"   = var.minecraft_enable_command_blocks
      "EULA"                   = "true"
      "MAX_PLAYERS"            = var.minecraft_max_players
      "MODS"                   = join(",",var.minecraft_mods)
      "MODE"                   = var.minecraft_mode
      "MOTD"                   = var.minecraft_motd
      "OPS"                    = join(",",var.minecraft_ops)
      "TYPE"                   = var.minecraft_type
      "VERSION"                = var.minecraft_version
      "WHITELIST"              = join(",",var.minecraft_users)
    }
    image                      = "itzg/minecraft-server" # https://github.com/itzg/docker-minecraft-server
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

  tags                         = local.tags
}

resource null_resource minecraft_server_log {
  triggers = {
    always                     = timestamp()
  }

  provisioner "local-exec" {
    command                    = "az container logs --ids ${azurerm_container_group.minecraft_server.id}"
  }
}

data azurerm_dns_zone vanity_domain {
  name                         = element(split("/",var.vanity_dns_zone_id),length(split("/",var.vanity_dns_zone_id))-1)
  resource_group_name          = element(split("/",var.vanity_dns_zone_id),length(split("/",var.vanity_dns_zone_id))-5)

  count                        = var.vanity_dns_zone_id != "" ? 1 : 0
}

resource azurerm_dns_cname_record vanity_hostname {
  name                         = "${var.vanity_hostname_prefix}${local.environment}"
  zone_name                    = data.azurerm_dns_zone.vanity_domain.0.name
  resource_group_name          = data.azurerm_dns_zone.vanity_domain.0.resource_group_name
  ttl                          = 300
  record                       = azurerm_container_group.minecraft_server.fqdn
  # target_resource_id           = azurerm_container_group.minecraft_server.id

  tags                         = local.tags
  count                        = var.vanity_dns_zone_id != "" ? 1 : 0
}