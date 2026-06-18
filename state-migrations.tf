moved {
  from = module.cosmos.azurerm_monitor_diagnostic_setting.this["cosmos"]
  to   = azurerm_monitor_diagnostic_setting.cosmos
}
