moved {
  from = module.cosmos.azurerm_monitor_diagnostic_setting.this["cosmos"]
  to   = azurerm_monitor_diagnostic_setting.cosmos
}

removed {
  from = azuread_application.github_actions

  lifecycle {
    destroy = false
  }
}
