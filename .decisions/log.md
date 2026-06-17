# Decision Log

## 2026-06-17

- **AI Foundry hub/project provisioning:** No stable Azure Verified Module was used for AI Foundry hub/project at scaffold time. Terraform uses native `azurerm` resources for Azure AI account/deployment plus `null_resource` + Azure CLI for hub/project bootstrap.
- **Entra External ID user flow provisioning:** No AVM exists for Entra External ID user flows. Terraform uses `null_resource` + Microsoft Graph via Azure CLI.

## 2026-06-17 — AVM Migration

- **VNet + Subnets + Peering:** Migrated to `Azure/avm-res-network-virtualnetwork/azurerm` (~> 0.17). NSGs and NSG rules kept as raw `azurerm_network_security_group` / `azurerm_network_security_rule` resources; the AVM module associates them via the `network_security_group` block in each subnet. Subnet-NSG associations and raw subnets removed (handled by module). Peering moved into the module's `peerings` map.
- **Key Vault + PE:** Migrated to `Azure/avm-res-keyvault-vault/azurerm` (~> 0.9). Private endpoint managed via the module's `private_endpoints` map. Raw `azurerm_key_vault_secret` resources kept for secret management.
- **ACR + PE:** Migrated to `Azure/avm-res-containerregistry-registry/azurerm` (~> 0.5). Private endpoint managed via the module's `private_endpoints` map.
- **Log Analytics:** Migrated to `Azure/avm-res-operationalinsights-workspace/azurerm` (~> 0.5). `azurerm_application_insights` kept as raw (no stable AVM).
- **Cosmos DB + PE + Diagnostics:** Migrated to `Azure/avm-res-documentdb-databaseaccount/azurerm` (~> 0.9). Private endpoint and diagnostic settings managed via module maps. SQL databases and containers managed via the module's `sql_databases` map.
- **Container Apps (kept raw):** No AVM migration — app-specific configuration, AVM adds minimal value for Container Apps.
- **Identity / RBAC (kept raw):** No AVM migration — role assignments are simple single-resource blocks.
- **AI Foundry (kept raw):** No stable AVM exists.
- **Entra (kept raw):** No AVM exists for Entra app registrations or External ID.
- Added `azapi` (~> 2.4) and `modtm` (~> 0.3) providers as required by AVM modules.
- All AVM modules configured with `enable_telemetry = false` and `tags = local.tags`.
