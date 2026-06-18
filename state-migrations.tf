moved {
  from = module.cosmos.azurerm_monitor_diagnostic_setting.this["cosmos"]
  to   = azurerm_monitor_diagnostic_setting.cosmos
}

removed {
  from = azurerm_role_assignment.key_vault_secrets_user_deployer

  lifecycle {
    destroy = false
  }
}

removed {
  from = azuread_application.github_actions

  lifecycle {
    destroy = false
  }
}
