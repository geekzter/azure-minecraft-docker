locals {
  config_directory             = ""
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
    versioning_enabled         = true
  }

  tags                         = local.tags
}

resource azurerm_storage_container configuration {
  name                         = "configuration"
  storage_account_id           = azurerm_storage_account.minecraft.id
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

# BUG: (azurerm 2.88) 
#      Error: parsing "***storecze-lock": parsing scope prefix: unable to find the scope prefix from the value "***storecze-lock" with the regex "^((.)***1,***)/providers/Microsoft.Authorization/locks/(.)***1,***"
resource azurerm_management_lock minecraft_data_lock {
  name                         = "${azurerm_storage_account.minecraft.name}-lock"
  scope                        = azurerm_storage_account.minecraft.id
  lock_level                   = "CanNotDelete"
  notes                        = "Do not accidentally delete Minecraft (world) data"

  depends_on                   = [
    module.minecraft
  ]
}

resource azurerm_recovery_services_vault backup {
  name                         = "${azurerm_resource_group.minecraft.name}-backup"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = azurerm_resource_group.minecraft.location
  sku                          = "Standard"
  immutability                 = "Unlocked"
  soft_delete_enabled          = true

  tags                         = local.tags

  count                        = var.enable_backup ? 1 : 0
}

resource azurerm_monitor_diagnostic_setting backup_vault {
  name                         = "${azurerm_recovery_services_vault.backup.0.name}-logs"
  target_resource_id           = azurerm_recovery_services_vault.backup.0.id
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.monitor.id

  enabled_log {
    category                   = "AddonAzureBackupAlerts"
  }
  enabled_log {
    category                   = "AddonAzureBackupJobs"
  }
  enabled_log {
    category                   = "AddonAzureBackupPolicy"
  }
  enabled_log {
    category                   = "AddonAzureBackupProtectedInstance"
  }
  enabled_log {
    category                   = "AddonAzureBackupStorage"
  }
  enabled_log {
    category                   = "AzureBackupReport"
  }
  enabled_log {
    category                   = "CoreAzureBackup"
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

  retention_weekly {
    count                      = 7
    weekdays                   = ["Monday"]
  }

  retention_monthly {
    count                      = 12
    weekdays                   = ["Monday","Sunday"]
    weeks                      = ["First", "Last"]
  }

  retention_yearly {
    count                      = 10
    weekdays                   = ["Monday"]
    weeks                      = ["First"]
    months                     = ["January"]
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

# Delay azurerm_backup_protected_file_share to mitigate race condition
resource time_sleep backup_container_sleep {
  create_duration              = "${var.backup_container_sleep_minutes}m"
  depends_on                   = [
                                  azurerm_backup_container_storage_account.minecraft,
                                  azurerm_backup_policy_file_share.nightly,
                                  azurerm_recovery_services_vault.backup,
                                  azurerm_resource_group.minecraft,
                                  azurerm_storage_account.minecraft,
                                  module.minecraft
  ]
}

# BUG: https://github.com/terraform-providers/terraform-provider-azurerm/issues/11184#issuecomment-870535683
#      [ERROR] fileshare 'minecraft-aci-experimental-data-xxxx' not found in protectable or protected fileshares, make sure Storage Account "minecraftstorxxxx" is registered with Recovery Service Vault "Minecraft-default-xxxx-backup" (Resource Group "Minecraft-default-xxxx")
resource azurerm_backup_protected_file_share minecraft_data {
  resource_group_name          = azurerm_resource_group.minecraft.name
  recovery_vault_name          = azurerm_recovery_services_vault.backup.0.name
  source_storage_account_id    = azurerm_storage_account.minecraft.id
  source_file_share_name       = module.minecraft[each.key].container_data_share_name
  backup_policy_id             = azurerm_backup_policy_file_share.nightly.0.id

  depends_on                   = [
    azurerm_backup_container_storage_account.minecraft,
    time_sleep.backup_container_sleep
  ]

  for_each                     = var.enable_backup ? toset(keys(var.minecraft_config)) : []
}

locals {
  all_resource_locks           = var.enable_backup ? concat(local.storage_resource_locks,local.backup_resource_locks) : local.storage_resource_locks
  backup_resource_locks        = [
      replace(azurerm_management_lock.minecraft_data_lock.id,azurerm_management_lock.minecraft_data_lock.name,"AzureBackupProtectionLock"),
  ]
  storage_resource_locks       = [
    azurerm_management_lock.minecraft_data_lock.id
  ]
}
