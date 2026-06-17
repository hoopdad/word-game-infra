resource "random_uuid" "api_access_scope" {}

resource "azuread_application" "api" {
  display_name     = local.names.api_app_registration
  sign_in_audience = "AzureADMyOrg"
  identifier_uris  = ["api://${local.names.api_app_registration}"]

  api {
    oauth2_permission_scope {
      id                         = random_uuid.api_access_scope.result
      value                      = "access_as_user"
      type                       = "User"
      enabled                    = true
      admin_consent_display_name = "Access Word Game API"
      admin_consent_description  = "Allows the app to call the Word Game API."
      user_consent_display_name  = "Access Word Game API"
      user_consent_description   = "Allows this app to call the Word Game API on your behalf."
    }
  }
}

resource "azuread_service_principal" "api" {
  client_id = azuread_application.api.client_id
}

resource "azuread_application" "web" {
  display_name                   = local.names.web_app_registration
  sign_in_audience               = "AzureADandPersonalMicrosoftAccount"
  fallback_public_client_enabled = true

  api {
    requested_access_token_version = 2
  }

  single_page_application {
    redirect_uris = var.web_redirect_uris
  }

  public_client {
    redirect_uris = var.public_client_redirect_uris
  }

  required_resource_access {
    resource_app_id = azuread_application.api.client_id

    resource_access {
      id   = random_uuid.api_access_scope.result
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "web" {
  client_id = azuread_application.web.client_id
}

resource "azuread_application" "github_actions" {
  display_name     = local.names.cicd_app_registration
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "azuread_application_federated_identity_credential" "github_actions_main" {
  application_id = azuread_application.github_actions.id
  display_name   = "${local.prefix}-github-main"
  description    = "OIDC trust for GitHub Actions deployments."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
}

resource "azurerm_role_assignment" "github_actions_rg_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

resource "null_resource" "external_id_signup_flow" {
  triggers = {
    tenant       = var.tenant_id
    flow_name    = "B2C_1A_${replace(local.prefix, "-", "_")}_signup_signin"
    display_name = "${local.prefix} sign-up and sign-in"
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      az rest --method POST --url "https://graph.microsoft.com/beta/identity/b2cUserFlows" --headers "Content-Type=application/json" --body "{\"id\":\"${self.triggers.flow_name}\",\"userFlowType\":\"signUpOrSignIn\",\"userFlowTypeVersion\":1,\"defaultLanguageTag\":\"en\",\"isLanguageCustomizationEnabled\":false}" >/dev/null 2>&1 || true
    EOT
  }
}
