locals {
  config_directory             = "${formatdate("YYYY",timestamp())}/${formatdate("MM",timestamp())}/${formatdate("DD",timestamp())}/${formatdate("hhmm",timestamp())}"
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
resource azurerm_storage_share minecraft_share2 {
  name                         = "minecraft-aci2-data-${local.suffix}"
  storage_account_name         = azurerm_storage_account.minecraft.name
  quota                        = 50
}

resource azurerm_storage_share minecraft_modpacks {
  name                         = "minecraft-aci-modpacks-${local.suffix}"
  storage_account_name         = azurerm_storage_account.minecraft.name
  quota                        = 50
}
resource azurerm_storage_share minecraft_modpacks2 {
  name                         = "minecraft-aci2-modpacks-${local.suffix}"
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

  for_each                     = toset(var.solution_contributors)
}

resource azurerm_storage_blob minecraft_backend_configuration {
  name                         = "${local.config_directory}/backend.tf"
  storage_account_name         = azurerm_storage_account.minecraft.name
  storage_container_name       = azurerm_storage_container.configuration.name
  type                         = "Block"
  source                       = "${path.root}/backend.tf"

  count                        = fileexists("${path.root}/backend.tf") ? 1 : 0
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

resource azurerm_storage_blob minecraft_workspace_vars_configuration {
  name                         = "${local.config_directory}/${terraform.workspace}.tfvars"
  storage_account_name         = azurerm_storage_account.minecraft.name
  storage_container_name       = azurerm_storage_container.configuration.name
  type                         = "Block"
  source                       = "${path.root}/${terraform.workspace}.tfvars"

  count                        = fileexists("${path.root}/${terraform.workspace}.tfvars") ? 1 : 0
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

  tags                         = local.tags

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_monitor_diagnostic_setting backup_vault {
  name                         = "${azurerm_recovery_services_vault.backup.0.name}-logs"
  target_resource_id           = azurerm_recovery_services_vault.backup.0.id
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id

  log {
    category                   = "AddonAzureBackupAlerts"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 365
    }
  }
  log {
    category                   = "AddonAzureBackupJobs"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 365
    }
  }
  log {
    category                   = "AddonAzureBackupPolicy"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 365
    }
  }
  log {
    category                   = "AddonAzureBackupProtectedInstance"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 365
    }
  }
  log {
    category                   = "AddonAzureBackupStorage"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 365
    }
  }
  log {
    category                   = "AzureBackupReport"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 365
    }
  }
  log {
    category                   = "CoreAzureBackup"
    enabled                    = true

    retention_policy {
      enabled                  = true
      days                     = 365
    }
  }

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_backup_policy_file_share nightly {
  name                         = "${azurerm_recovery_services_vault.backup.0.name}-nightly"
  resource_group_name          = azurerm_recovery_services_vault.backup.0.resource_group_name
  recovery_vault_name          = azurerm_recovery_services_vault.backup.0.name

  timezone                     = var.timezone

  backup {
    frequency                  = "Daily"
    time                       = "03:00"
  }

  retention_daily {
    count                      = 30
  }

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_backup_container_storage_account minecraft {
  resource_group_name          = azurerm_resource_group.minecraft.name
  recovery_vault_name          = azurerm_recovery_services_vault.backup.0.name
  storage_account_id           = azurerm_storage_account.minecraft.id

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_backup_protected_file_share minecraft_data {
  resource_group_name          = azurerm_resource_group.minecraft.name
  recovery_vault_name          = azurerm_recovery_services_vault.backup.0.name
  source_storage_account_id    = azurerm_storage_account.minecraft.id
  source_file_share_name       = azurerm_storage_share.minecraft_share.name
  backup_policy_id             = azurerm_backup_policy_file_share.nightly.0.id

  depends_on                   = [azurerm_backup_container_storage_account.minecraft]

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_management_lock minecraft_backup_lock {
  name                         = "${azurerm_recovery_services_vault.backup.0.name}-lock"
  scope                        = azurerm_recovery_services_vault.backup.0.id
  lock_level                   = "CanNotDelete"
  notes                        = "Do not accidentally delete Minecraft (world) backups"

  count                        = var.enable_backup ? 1 : 0

  depends_on                   = [
    azurerm_backup_protected_file_share.minecraft_data,
    azurerm_storage_share.minecraft_modpacks,
    azurerm_monitor_diagnostic_setting.backup_vault
  ]
}

locals {
  all_resource_locks           = var.enable_backup ? concat(local.storage_resource_locks,local.backup_resource_locks) : local.storage_resource_locks
  backup_resource_locks        = concat(
    azurerm_management_lock.minecraft_backup_lock.*.id,
    [
      replace(azurerm_management_lock.minecraft_data_lock.id,azurerm_management_lock.minecraft_data_lock.name,"AzureBackupProtectionLock"),
    ],
  )
  storage_resource_locks       = [
    azurerm_management_lock.minecraft_data_lock.id
  ]
}
