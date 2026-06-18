module "managed_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "~> 0.5"

  name                = local.names.managed_identity
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  enable_telemetry    = false
  tags                = local.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.acr.resource_id
  role_definition_name = "AcrPull"
  principal_id         = module.managed_identity.principal_id
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_data_contributor" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = module.cosmos.name
  role_definition_id  = "${module.cosmos.resource_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = module.managed_identity.principal_id
  scope               = module.cosmos.resource_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.managed_identity.principal_id
}

resource "azurerm_role_assignment" "cognitive_services_user" {
  scope                = module.foundry_account.resource_id
  role_definition_name = "Cognitive Services User"
  principal_id         = module.managed_identity.principal_id
}

resource "azurerm_role_assignment" "foundry_private_endpoint_rg_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = module.foundry_account.system_assigned_mi_principal_id
}
