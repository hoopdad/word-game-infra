# Decision Log

## 2026-06-17

- **Entra External ID user flow provisioning:** No AVM exists for Entra External ID user flows. Entra provisioning is handled outside Terraform via `scripts/setup-entra-external-id.sh`.

## 2026-06-17 — AVM Migration

- **VNet + Subnets + Peering:** Migrated to `Azure/avm-res-network-virtualnetwork/azurerm` (~> 0.17). NSGs and NSG rules kept as raw `azurerm_network_security_group` / `azurerm_network_security_rule` resources; the AVM module associates them via the `network_security_group` block in each subnet. Subnet-NSG associations and raw subnets removed (handled by module). Peering moved into the module's `peerings` map.
- **Key Vault + PE:** Migrated to `Azure/avm-res-keyvault-vault/azurerm` (~> 0.9). Private endpoint managed via the module's `private_endpoints` map. Raw `azurerm_key_vault_secret` resources kept for secret management.
- **ACR + PE:** Migrated to `Azure/avm-res-containerregistry-registry/azurerm` (~> 0.5). Private endpoint managed via the module's `private_endpoints` map.
- **Log Analytics:** Migrated to `Azure/avm-res-operationalinsights-workspace/azurerm` (~> 0.5). `azurerm_application_insights` kept as raw (no stable AVM).
- **Cosmos DB + PE + Diagnostics:** Migrated to `Azure/avm-res-documentdb-databaseaccount/azurerm` (~> 0.9). Private endpoint and diagnostic settings managed via module maps. SQL databases and containers managed via the module's `sql_databases` map.
- **Container App Environments:** Migrated to `Azure/avm-res-app-managedenvironment/azurerm` (~> 0.5). Both internal and edge environments use delegated subnets and keep environment-level diagnostics.
- **Identity:** Migrated user-assigned managed identity to `Azure/avm-res-managedidentity-userassignedidentity/azurerm` (~> 0.5). RBAC role assignments remain raw `azurerm` resources.
- **AI Foundry account/deployment:** Migrated to `Azure/avm-res-cognitiveservices-account/azurerm` (~> 0.11) with `allow_project_management = true` and GPT-4.1-mini `GlobalStandard` deployment scale.
- **AI Foundry project:** Kept as `azapi_resource` (`Microsoft.CognitiveServices/accounts/projects@2025-06-01`) because this child resource still requires azapi in this stack.
- **Cosmos DB data-plane role assignment:** Used raw `azurerm_cosmosdb_sql_role_assignment` because this is a Cosmos SQL data-plane role model, not an Azure RBAC assignment.
- Added `azapi` (~> 2.4) and `modtm` (~> 0.3) providers as required by AVM modules.
- All AVM modules configured with `enable_telemetry = false` and `tags = local.tags`.
