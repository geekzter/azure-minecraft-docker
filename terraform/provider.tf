terraform {
  required_providers {
    azuread                    = "~> 2.12"
    azurerm                    = "~> 3.0"
    http                       = "~> 2.1"
    null                       = "~> 3.1"
    random                     = "~> 3.1"
    time                       = "~> 0.7"
  }
  required_version             = "~> 1.0, != 1.1.0" # BUG: https://github.com/hashicorp/terraform/issues/30110
}

# Microsoft Azure Resource Manager Provider
# HACK: Allow overriding of subscription_id/tenant_id with variables
provider azurerm {
  alias                        = "defaults"
  features {}
}
data azurerm_subscription default {
  provider                     = azurerm.defaults
}
provider azuread {
  tenant_id                    = var.tenant_id != null && var.tenant_id != "" ? var.tenant_id : data.azurerm_subscription.default.tenant_id
}
provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    template_deployment {
      delete_nested_items_during_deletion = true
    }
  }
  subscription_id              = var.subscription_id != null && var.subscription_id != "" ? var.subscription_id : data.azurerm_subscription.default.subscription_id
  tenant_id                    = var.tenant_id != null && var.tenant_id != "" ? var.tenant_id : data.azurerm_subscription.default.tenant_id
}
data azurerm_subscription primary {}