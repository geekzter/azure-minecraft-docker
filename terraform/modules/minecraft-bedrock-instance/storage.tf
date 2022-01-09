locals {
  config_directory             = var.name
}

data azurerm_storage_account minecraft {
  name                         = var.storage_account_name
  resource_group_name          = var.resource_group_name
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
  source_content               = jsonencode(var.minecraft_user_names)
}

resource azurerm_storage_share minecraft_share {
  name                         = var.container_data_share_name
  storage_account_name         = var.storage_account_name
  quota                        = 50

  acl {
    id                         = uuid()

    access_policy {
      permissions              = "rwdl"
    }
  }
}