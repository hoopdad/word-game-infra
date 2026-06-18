output "resource_group_name" {
  description = "Resource group name."
  value       = azurerm_resource_group.main.name
}

output "container_app_environment_ids" {
  description = "Container App Environment resource IDs."
  value = {
    internal = module.container_app_environment_internal.resource_id
    edge     = module.container_app_environment_edge.resource_id
  }
}

output "container_app_environment_names" {
  description = "Container App Environment names."
  value = {
    internal = module.container_app_environment_internal.name
    edge     = module.container_app_environment_edge.name
  }
}

output "container_app_environment_default_domains" {
  description = "Container App Environment default domains."
  value = {
    internal = module.container_app_environment_internal.default_domain
    edge     = module.container_app_environment_edge.default_domain
  }
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint."
  value       = module.cosmos.endpoint
}

output "acr_login_server" {
  description = "Azure Container Registry login server."
  value       = module.acr.resource.login_server
}

output "key_vault_uri" {
  description = "Key Vault URI."
  value       = module.key_vault.uri
}

output "managed_identity_client_id" {
  description = "User-assigned managed identity client ID."
  value       = module.managed_identity.client_id
}
