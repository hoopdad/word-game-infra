module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  name                          = local.names.key_vault
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  public_network_access_enabled = false
  soft_delete_retention_days    = 7
  enable_telemetry              = false
  tags                          = local.tags

  private_endpoints = {
    "vault" = {
      subnet_resource_id = module.vnet.subnets["private_endpoints"].resource_id
    }
  }
}

resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-connection-string"
  key_vault_id = module.key_vault.resource_id
  value        = "AccountEndpoint=${module.cosmos.endpoint};AccountKey=${module.cosmos.cosmosdb_keys.primary_key};"

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "foundry_endpoint" {
  name         = "foundry-endpoint"
  key_vault_id = module.key_vault.resource_id
  value        = azurerm_cognitive_account.foundry.endpoint

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "foundry_key" {
  name         = "foundry-key"
  key_vault_id = module.key_vault.resource_id
  value        = local.foundry_api_key_value

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "entra_web_client_id" {
  name         = "entra-web-client-id"
  key_vault_id = module.key_vault.resource_id
  value        = azuread_application.web.client_id

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "entra_api_client_id" {
  name         = "entra-api-client-id"
  key_vault_id = module.key_vault.resource_id
  value        = azuread_application.api.client_id

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}
