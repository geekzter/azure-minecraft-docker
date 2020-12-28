terraform {
  required_providers {
    azurerm                    = "~> 2.41"
    docker = {
      source                   = "kreuzwerker/docker"
      version                  = "~> 2.9.0"
    }
    null                       = "~> 3.0.0"
    random                     = "~> 3.0.0"
  }
  required_version             = "~> 0.14.0"
}

# Microsoft Azure Resource Manager Provider
provider azurerm {
  features {}
  subscription_id              = var.subscription_id
  tenant_id                    = var.tenant_id
}