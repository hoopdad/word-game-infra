module "cosmos" {
  source  = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version = "~> 0.9"

  name                = local.names.cosmos_account
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  enable_telemetry    = false
  tags                = local.tags

  consistency_policy = {
    consistency_level = "Session"
  }

  capabilities = [{
    name = "EnableServerless"
  }]

  geo_locations = [{
    location          = azurerm_resource_group.main.location
    failover_priority = 0
    zone_redundant    = false
  }]

  public_network_access_enabled = false
  local_authentication_disabled = true

  sql_databases = {
    "word-game" = {
      name = local.names.cosmos_database
      containers = {
        "users" = {
          name                = "users"
          partition_key_paths = ["/id"]
        }
        "games" = {
          name                = "games"
          partition_key_paths = ["/id"]
        }
        "scores" = {
          name                = "scores"
          partition_key_paths = ["/userId"]
        }
        "category_config" = {
          name                = "category_config"
          partition_key_paths = ["/id"]
        }
      }
    }
  }

  private_endpoints = {
    "cosmos" = {
      subnet_resource_id = module.vnet.subnets["private_endpoints"].resource_id
      subresource_name   = "Sql"
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  name                       = "${local.prefix}-diag-cosmos"
  target_resource_id         = module.cosmos.resource_id
  log_analytics_workspace_id = module.log_analytics.resource_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "Requests"
  }
}
