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
# subscription_guid            = split("/",azurerm_resource_group.minecraft.id)[1]
  suffix                       = var.resource_suffix != "" ? lower(var.resource_suffix) : random_string.suffix.result
  tags                         = {
    application                = "Minecraft"
    environment                = local.environment
    provisioner                = "terraform"
    provisoner-email           = var.provisoner_email_address
    repository                 = "azure-minecraft-docker"
    runid                      = var.run_id
    suffix                     = local.suffix
    workspace                  = terraform.workspace
  }

  lifecycle                    = {
    ignore_changes             = ["tags"]
  }
}

resource azurerm_resource_group minecraft {
  name                         = "Minecraft-${terraform.workspace}-${local.suffix}"
  location                     = var.location

  tags                         = local.tags
}

resource azurerm_user_assigned_identity minecraft_identity {
  name                         = "${azurerm_resource_group.minecraft.name}-minecraft-identity"
  resource_group_name          = azurerm_resource_group.minecraft.name
  location                     = var.location

  tags                         = local.tags
}

# Requires Terraform owner access to resource group, in order to be able to perform access management
resource azurerm_role_assignment backup_operators {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Backup Operator"
  principal_id                 = each.value

  for_each                     = toset(var.solution_operators)
}

# resource random_uuid container_operator {}
resource azurerm_role_definition container_operator {
  name                         = "Minecraft Container Operator (${terraform.workspace})"
  # role_definition_id           = random_uuid.container_operator.result
  scope                        = azurerm_resource_group.minecraft.id
  description                  = "This is a custom role created via Terraform"

  permissions {
    actions                    = [
      "Microsoft.ContainerInstance/containerGroups/*/action",
      "Microsoft.ContainerInstance/containerGroups/*/read",
    ]
    not_actions                = []
  }

  assignable_scopes            = [
    azurerm_resource_group.minecraft.id
  ]

  count                        = length(var.solution_operators) > 0 ? 1 : 0
}
resource azurerm_role_assignment container_operators {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_id           = azurerm_role_definition.container_operator.0.role_definition_resource_id
  principal_id                 = each.value

  for_each                     = toset(var.solution_operators)
}
resource azurerm_role_assignment contributor {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Contributor"
  principal_id                 = each.value

  for_each                     = toset(var.solution_contributors)
}
resource azurerm_role_assignment file_data_contributor {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Storage File Data SMB Share Contributor"
  principal_id                 = each.value

  for_each                     = toset(var.solution_contributors)
}
resource azurerm_role_assignment file_data_reader {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Storage File Data SMB Share Reader"
  principal_id                 = each.value

  for_each                     = setunion(toset(var.solution_operators),toset(var.solution_readers))
}
resource azurerm_role_assignment storage_data_reader {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Storage Blob Data Reader"
  principal_id                 = each.value

  for_each                     = setunion(toset(var.solution_operators),toset(var.solution_readers),toset(var.solution_contributors))
}
resource azurerm_role_assignment logic_app_operators {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Logic App Operator"
  principal_id                 = each.value

  for_each                     = toset(var.solution_operators)
}
# resource random_uuid logic_app_runner {}
resource azurerm_role_definition logic_app_runner {
  name                         = "Minecraft Logic App Runners (${terraform.workspace})"
  # role_definition_id           = random_uuid.logic_app_runner.result
  scope                        = azurerm_resource_group.minecraft.id
  description                  = "This is a custom role created via Terraform"

  permissions {
    actions                    = [
      "Microsoft.Logic/workflows/triggers/run/action",
    ]
    not_actions                = []
  }

  assignable_scopes            = [
    azurerm_resource_group.minecraft.id
  ]

  count                        = length(var.solution_operators) > 0 ? 1 : 0
}
resource azurerm_role_assignment logic_app_runners {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_id           = azurerm_role_definition.logic_app_runner.0.role_definition_resource_id
  principal_id                 = each.value

  for_each                     = toset(var.solution_operators)
}
resource azurerm_role_assignment readers {
  scope                        = azurerm_resource_group.minecraft.id
  role_definition_name         = "Reader"
  principal_id                 = each.value

  for_each                     = setunion(toset(var.solution_operators),toset(var.solution_readers))
}
