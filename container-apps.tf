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
    infrastructure_subnet_id = module.vnet.subnets["container_apps"].resource_id
    internal                 = true
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
