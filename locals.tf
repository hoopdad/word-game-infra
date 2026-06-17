locals {
  env    = lower(var.environment)
  region = lower(var.location)
  prefix = "wordgame-${local.env}"

  tags = merge(
    {
      project     = "word-game"
      environment = local.env
      managed_by  = "terraform"
    },
    var.common_tags,
  )

  names = {
    resource_group          = "${local.prefix}-rg"
    vnet                    = "${local.prefix}-vnet"
    ingress_subnet          = "${local.prefix}-ingress-snet"
    container_apps_subnet   = "${local.prefix}-containerapps-snet"
    private_endpoint_subnet = "${local.prefix}-privateendpoints-snet"
    ingress_nsg             = "${local.prefix}-ingress-nsg"
    container_apps_nsg      = "${local.prefix}-containerapps-nsg"
    private_endpoint_nsg    = "${local.prefix}-privateendpoints-nsg"
    log_analytics           = "${local.prefix}-law"
    app_insights            = "${local.prefix}-appi"
    managed_identity        = "${local.prefix}-ca-mi"
    internal_cae            = "${local.prefix}-cae-internal"
    edge_cae                = "${local.prefix}-cae-edge"
    web_app                 = "word-game-web"
    api_app                 = "word-game-api"
    agent_app               = "word-game-agent"
    waf_app                 = "word-game-waf"
    cosmos_account          = "${local.prefix}-cosmos"
    cosmos_database         = "word-game"
    key_vault               = "${local.prefix}-kv"
    foundry_account         = "${local.prefix}-foundry"
    foundry_hub             = "${local.prefix}-foundry-hub"
    foundry_project         = "${local.prefix}-foundry-project"
    acr                     = "wordgame${local.env}acr"
    web_app_registration    = "${local.prefix}-web"
    api_app_registration    = "${local.prefix}-api"
    cicd_app_registration   = "${local.prefix}-gha"
  }

  cidr = {
    vnet              = "10.42.0.0/16"
    ingress           = "10.42.0.0/24"
    container_apps    = "10.42.1.0/23"
    private_endpoints = "10.42.3.0/24"
  }

  foundry_api_key_value = var.foundry_api_key_override != "" ? var.foundry_api_key_override : azurerm_cognitive_account.foundry.primary_access_key
}
