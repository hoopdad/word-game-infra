provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azurerm" {
  alias = "hub"
  features {}
  subscription_id = var.hub_subscription_id != "" ? var.hub_subscription_id : var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}
