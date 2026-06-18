module "container_app_environment_internal" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "~> 0.5"

  name                = local.names.internal_cae
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  enable_telemetry    = false
  tags                = local.tags

  log_analytics_workspace = {
    resource_id = module.log_analytics.resource_id
  }

  vnet_configuration = {
    infrastructure_subnet_id = azurerm_subnet.container_apps.id
    internal                 = true
  }
}


# Edge CAE — public-facing environment on ingress subnet for WAF
module "container_app_environment_edge" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "~> 0.5"

  name                = local.names.edge_cae
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  enable_telemetry    = false
  tags                = local.tags

  log_analytics_workspace = {
    resource_id = module.log_analytics.resource_id
  }

  vnet_configuration = {
    infrastructure_subnet_id = azurerm_subnet.ingress.id
    internal                 = false
  }
}

resource "azurerm_monitor_diagnostic_setting" "container_app_environment_edge" {
  name                       = "${local.prefix}-diag-cae-edge"
  target_resource_id         = module.container_app_environment_edge.resource_id
  log_analytics_workspace_id = module.log_analytics.resource_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "container_app_environment_internal" {
  name                       = "${local.prefix}-diag-cae-internal"
  target_resource_id         = module.container_app_environment_internal.resource_id
  log_analytics_workspace_id = module.log_analytics.resource_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Private endpoint for internal CAE — enables DNS resolution from hub VNet
resource "azurerm_private_endpoint" "cae_internal" {
  name                = "${local.prefix}-pe-cae-internal"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.prefix}-psc-cae-internal"
    private_connection_resource_id = module.container_app_environment_internal.resource_id
    subresource_names              = ["managedEnvironments"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "cae-dns-zone-group"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.container_apps.id
    ]
  }

  lifecycle {
    ignore_changes = [subnet_id]
  }
}

resource "azurerm_private_dns_zone" "container_apps" {
  name                = "azurecontainerapps.io"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "container_apps" {
  name                  = "${local.prefix}-cae-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.container_apps.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
  tags                  = local.tags
}
