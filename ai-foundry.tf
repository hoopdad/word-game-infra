resource "azurerm_cognitive_account" "foundry" {
  name                = local.names.foundry_account
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "AIServices"
  sku_name            = "S0"

  custom_subdomain_name         = replace(local.names.foundry_account, "-", "")
  public_network_access_enabled = false

  tags = local.tags
}

resource "azurerm_cognitive_deployment" "gpt_41_mini" {
  name                 = "gpt-41-mini"
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = "OpenAI"
    name    = var.foundry_model_name
    version = var.foundry_model_version
  }

  sku {
    name     = "Standard"
    capacity = 1
  }
}

resource "azapi_resource" "foundry_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = local.names.foundry_project
  location  = azurerm_resource_group.main.location
  parent_id = azurerm_cognitive_account.foundry.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {}
  }

  tags = local.tags
}
