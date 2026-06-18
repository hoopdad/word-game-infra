module "foundry_account" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "~> 0.11"

  name                     = local.names.foundry_account
  location                 = azurerm_resource_group.main.location
  parent_id                = azurerm_resource_group.main.id
  kind                     = "AIServices"
  sku_name                 = "S0"
  allow_project_management = true

  custom_subdomain_name         = replace(local.names.foundry_account, "-", "")
  public_network_access_enabled = false
  enable_telemetry              = false
  tags                          = local.tags

  cognitive_deployments = {
    "gpt_41_mini" = {
      name = "gpt-41-mini"
      model = {
        format  = "OpenAI"
        name    = var.foundry_model_name
        version = var.foundry_model_version
      }
      scale = {
        capacity = 1
        type     = "GlobalStandard"
      }
    }
  }
}

resource "azapi_resource" "foundry_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = local.names.foundry_project
  location  = azurerm_resource_group.main.location
  parent_id = module.foundry_account.resource_id

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      description = "Word Game AI Foundry project"
      displayName = local.names.foundry_project
    }
  }

  tags = local.tags
}
