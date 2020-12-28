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

resource azurerm_recovery_services_vault backup {
  name                         = "${azurerm_resource_group.minecraft.name}-backup"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  sku                          = "Standard"
  soft_delete_enabled          = true

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_management_lock minecraft_backup_lock {
  name                         = "${azurerm_recovery_services_vault.backup.0.name}-lock"
  scope                        = azurerm_recovery_services_vault.backup.0.id
  lock_level                   = "CanNotDelete"
  notes                        = "Do not accidentally delete Minecraft (world) backups"

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_backup_policy_file_share nightly {
  name                         = "${azurerm_recovery_services_vault.backup.0.name}-nightly"
  resource_group_name          = azurerm_recovery_services_vault.backup.0.resource_group_name
  recovery_vault_name          = azurerm_recovery_services_vault.backup.0.name

  timezone                     = "W. Europe Standard Time"

  backup {
    frequency                  = "Daily"
    time                       = "03:00"
  }

  retention_daily {
    count                      = 10
  }

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_backup_container_storage_account minecraft {
  resource_group_name          = azurerm_resource_group.minecraft.name
  recovery_vault_name          = azurerm_recovery_services_vault.backup.0.name
  storage_account_id           = azurerm_storage_account.minecraft.id

  # provisioner local-exec {
  #   command                    = "az backup protection disable -v ${self.recovery_vault_name} -g ${self.resource_group_name} -c ${split("/",self.storage_account_id)[8]} -i minecraft-aci-data-${split("-",self.resource_group_name)[2]} --delete-backup-data true -y -o table"
  #   when                       = destroy
  # }

  count                        = var.enable_backup ? 1 : 0
}

# BUG: https://github.com/terraform-providers/terraform-provider-azurerm/issues/9452
resource azurerm_backup_protected_file_share minecraft_data {
  resource_group_name          = azurerm_resource_group.minecraft.name
  recovery_vault_name          = azurerm_recovery_services_vault.backup.0.name
  source_storage_account_id    = azurerm_storage_account.minecraft.id
  source_file_share_name       = azurerm_storage_share.minecraft_share.name
  backup_policy_id             = azurerm_backup_policy_file_share.nightly.0.id

  depends_on                   = [azurerm_backup_container_storage_account.minecraft]

  count                        = var.enable_backup ? 1 : 0
}
# HACK: Use Azure CLI instead
# BUG: az backup protection enable-for-azurefileshare --ids /subscriptions/84c1a2c7-585a-4753-ad28-97f69618cf12/resourceGroups/Minecraft-default-mmbm/providers/Microsoft.RecoveryServices/vaults/Minecraft-default-mmbm-backup --policy-name Minecraft-default-mmbm-backup-nightly --storage-account minecraftstormmbm --azure-file-share minecraft-aci-data-mmbm -o table
# resource null_resource mineecraft_data_backup {
#   provisioner local-exec {
#     command                    = "az backup protection enable-for-azurefileshare --ids ${azurerm_recovery_services_vault.backup.0.id} --policy-name ${azurerm_backup_policy_file_share.nightly.0.name} --storage-account ${azurerm_storage_account.minecraft.name} --azure-file-share ${azurerm_storage_share.minecraft_share.name} -o table"
#   }

#   count                        = var.enable_backup ? 1 : 0

#   depends_on                   = [
#     azurerm_backup_container_storage_account.minecraft
#   ]
# }