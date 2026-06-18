module "acr" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "~> 0.5"

  name                          = local.names.acr
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = true
  enable_telemetry              = false
  tags                          = local.tags

  private_endpoints = {
    "registry" = {
      subnet_resource_id = azurerm_subnet.private_endpoints.id
    }
  }
}
