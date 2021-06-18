locals {
  config_directory             = "${formatdate("YYYY",timestamp())}/${formatdate("MM",timestamp())}/${formatdate("DD",timestamp())}/${formatdate("hhmm",timestamp())}/${var.name}"
}

resource azurerm_storage_blob minecraft_configuration {
  name                         = "${local.config_directory}/config.json"
  storage_account_name         = var.storage_account_name
  storage_container_name       = var.configuration_storage_container_name
  type                         = "Block"
  source_content               = jsonencode(local.config)
}

resource azurerm_storage_blob minecraft_environment {
  name                         = "${local.config_directory}/environment.json"
  storage_account_name         = var.storage_account_name
  storage_container_name       = var.configuration_storage_container_name
  type                         = "Block"
  source_content               = jsonencode(local.environment_variables)
}

resource azurerm_storage_blob minecraft_user_configuration {
  name                         = "${local.config_directory}/users.json"
  storage_account_name         = var.storage_account_name
  storage_container_name       = var.configuration_storage_container_name
  type                         = "Block"
  source_content               = jsonencode(var.minecraft_users)
}

# https://www.spigotmc.org/resources/console-spam-fix.18410/download?version=366123
resource azurerm_storage_share_directory plugins {
  name                         = "plugins"
  share_name                   = var.container_data_share_name
  storage_account_name         = var.storage_account_name

  count                        = var.enable_log_filter ? 1 : 0
}
resource azurerm_storage_share_directory bstats {
  name                         = "${azurerm_storage_share_directory.plugins.0.name}/bStats"
  share_name                   = var.container_data_share_name
  storage_account_name         = var.storage_account_name

  count                        = var.enable_log_filter ? 1 : 0
}
resource azurerm_storage_share_file bstats_config {
  name                         = "config.yml"
  path                         = azurerm_storage_share_directory.bstats.0.name
  storage_share_id             = var.container_data_share_id
  source                       = "${path.root}/../minecraft/bstats/config.yml"
  content_type                 = "application/yaml"

  count                        = var.enable_log_filter ? 1 : 0
}
resource azurerm_storage_share_directory log_filter {
  name                         = "${azurerm_storage_share_directory.plugins.0.name}/ConsoleSpamFix"
  share_name                   = var.container_data_share_name
  storage_account_name         = var.storage_account_name

  count                        = var.enable_log_filter ? 1 : 0
}
resource azurerm_storage_share_file log_filter_config {
  name                         = "config.yml"
  path                         = azurerm_storage_share_directory.log_filter.0.name
  storage_share_id             = var.container_data_share_id
  source                       = "${path.root}/../minecraft/log-filter/config.yml"
  content_type                 = "application/yaml"

  count                        = var.enable_log_filter ? 1 : 0
}
resource null_resource log_filter_jar {
  provisioner local-exec {
    command                    = "${path.root}/../scripts/download_plugins.ps1 -Url ${var.log_filter_jar}"
    interpreter                = ["pwsh","-nop","-c"]
  }

  count                        = var.enable_log_filter && !fileexists("${path.root}/../minecraft/plugins/${basename(var.log_filter_jar)}") ? 1 : 0
}
resource azurerm_storage_share_file log_filter_jar {
  name                         = basename(var.log_filter_jar)
  path                         = azurerm_storage_share_directory.plugins.0.name
  storage_share_id             = var.container_data_share_id
  source                       = "${path.root}/../minecraft/plugins/${basename(var.log_filter_jar)}"
  content_type                 = "application/java-archive"

  count                        = var.enable_log_filter ? 1 : 0

  depends_on                   = [
    azurerm_storage_share_file.log_filter_config,
    null_resource.log_filter_jar
  ]
}
