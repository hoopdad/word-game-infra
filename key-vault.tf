resource "azurerm_key_vault" "main" {
  name                = local.names.key_vault
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled    = true
  public_network_access_enabled = false
  soft_delete_retention_days    = 7

  tags = local.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "${local.prefix}-kv-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-connection-string"
  key_vault_id = azurerm_key_vault.main.id
  value        = "AccountEndpoint=${azurerm_cosmosdb_account.main.endpoint};AccountKey=${azurerm_cosmosdb_account.main.primary_key};"

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "foundry_endpoint" {
  name         = "foundry-endpoint"
  key_vault_id = azurerm_key_vault.main.id
  value        = azurerm_cognitive_account.foundry.endpoint

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "foundry_key" {
  name         = "foundry-key"
  key_vault_id = azurerm_key_vault.main.id
  value        = local.foundry_api_key_value

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "entra_web_client_id" {
  name         = "entra-web-client-id"
  key_vault_id = azurerm_key_vault.main.id
  value        = azuread_application.web.client_id

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}

resource "azurerm_key_vault_secret" "entra_api_client_id" {
  name         = "entra-api-client-id"
  key_vault_id = azurerm_key_vault.main.id
  value        = azuread_application.api.client_id

  depends_on = [azurerm_role_assignment.key_vault_secrets_user]
}
