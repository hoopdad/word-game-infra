resource "azurerm_container_registry" "main" {
  name                = local.names.acr
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.enable_acr_private_endpoint ? "Premium" : "Basic"
  admin_enabled       = false

  public_network_access_enabled = var.enable_acr_private_endpoint ? false : true
  tags                          = local.tags
}

resource "azurerm_private_endpoint" "acr" {
  count = var.enable_acr_private_endpoint ? 1 : 0

  name                = "${local.prefix}-acr-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.prefix}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}
