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
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

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
  value        = module.foundry_account.endpoint

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "foundry_key" {
  name             = "foundry-key"
  key_vault_id     = module.key_vault.resource_id
  value_wo         = local.foundry_api_key_value
  value_wo_version = var.foundry_key_secret_value_version

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "entra_web_client_id" {
  count = var.entra_web_client_id != "" ? 1 : 0

  name         = "entra-web-client-id"
  key_vault_id = module.key_vault.resource_id
  value        = var.entra_web_client_id

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "entra_api_client_id" {
  count = var.entra_api_client_id != "" ? 1 : 0

  name         = "entra-api-client-id"
  key_vault_id = module.key_vault.resource_id
  value        = var.entra_api_client_id

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}
