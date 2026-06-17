output "resource_group_name" {
  description = "Resource group name."
  value       = azurerm_resource_group.main.name
}

output "container_app_fqdns" {
  description = "Container App FQDNs keyed by application name."
  value = {
    word_game_web   = azurerm_container_app.web.latest_revision_fqdn
    word_game_api   = azurerm_container_app.api.latest_revision_fqdn
    word_game_agent = azurerm_container_app.agent.latest_revision_fqdn
    word_game_waf   = azurerm_container_app.waf.latest_revision_fqdn
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
  value       = azurerm_user_assigned_identity.container_apps.client_id
}

output "entra_web_client_id" {
  description = "Web app registration client ID."
  value       = azuread_application.web.client_id
}

output "entra_api_client_id" {
  description = "API app registration client ID."
  value       = azuread_application.api.client_id
}

output "entra_tenant_id" {
  description = "Microsoft Entra tenant ID."
  value       = var.tenant_id
}

output "github_actions_client_id" {
  description = "GitHub Actions OIDC app registration client ID."
  value       = azuread_application.github_actions.client_id
}
