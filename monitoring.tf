data "azurerm_log_analytics_workspace" "hub" {
  count               = var.hub_law_name != "" ? 1 : 0
  provider            = azurerm.hub
  name                = var.hub_law_name
  resource_group_name = var.hub_resource_group_name
}

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "~> 0.5"

  name                                      = local.names.log_analytics
  location                                  = azurerm_resource_group.main.location
  resource_group_name                       = azurerm_resource_group.main.name
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_daily_quota_gb    = var.log_analytics_daily_quota_gb
  enable_telemetry                          = false
  tags                                      = local.tags
}

resource "azurerm_application_insights" "main" {
  name                = local.names.app_insights
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = module.log_analytics.resource_id
  application_type    = "web"
  tags                = local.tags
}
