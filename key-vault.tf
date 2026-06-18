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
      subnet_resource_id = azurerm_subnet.private_endpoints.id
    }
  }
}

# Note: secrets are managed at runtime by the deploy script which has VNet
# access. Terraform cannot write to the private Key Vault from outside the VNet.
# The managed identity has Key Vault Secrets User role for runtime reads.
