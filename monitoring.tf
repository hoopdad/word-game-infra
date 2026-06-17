data "azurerm_log_analytics_workspace" "hub" {
  count               = var.hub_law_name != "" ? 1 : 0
  provider            = azurerm.hub
  name                = var.hub_law_name
  resource_group_name = var.hub_resource_group_name
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.names.log_analytics
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  daily_quota_gb      = var.log_analytics_daily_quota_gb
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "main" {
  name                = local.names.app_insights
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.tags
}
