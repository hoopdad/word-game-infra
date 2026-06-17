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

resource "null_resource" "foundry_hub_project" {
  triggers = {
    resource_group = azurerm_resource_group.main.name
    location       = azurerm_resource_group.main.location
    hub_name       = local.names.foundry_hub
    project_name   = local.names.foundry_project
    subscription   = var.subscription_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      az extension add --name ml --only-show-errors >/dev/null 2>&1 || true
      az ml workspace create --resource-group ${self.triggers.resource_group} --name ${self.triggers.hub_name} --location ${self.triggers.location} --kind hub --only-show-errors >/dev/null
      az ml workspace create --resource-group ${self.triggers.resource_group} --name ${self.triggers.project_name} --location ${self.triggers.location} --kind project --hub-id /subscriptions/${self.triggers.subscription}/resourceGroups/${self.triggers.resource_group}/providers/Microsoft.MachineLearningServices/workspaces/${self.triggers.hub_name} --only-show-errors >/dev/null
    EOT
  }

  depends_on = [azurerm_cognitive_account.foundry]
}
