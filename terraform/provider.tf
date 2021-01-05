terraform {
  required_providers {
    azuread                    = ">= 1.1.1"
    azurerm                    = "~> 2.41"
    null                       = "~> 3.0.0"
    random                     = "~> 3.0.0"
  }
  required_version             = "~> 0.14.0"
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
provider azurerm {
  features {
    template_deployment {
      delete_nested_items_during_deletion = true
    }
  }
  subscription_id              = var.subscription_id != null && var.subscription_id != "" ? var.subscription_id : data.azurerm_subscription.default.subscription_id
  tenant_id                    = var.tenant_id != null && var.tenant_id != "" ? var.tenant_id : data.azurerm_subscription.default.tenant_id
}
data azurerm_subscription primary {}