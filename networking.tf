resource "azurerm_resource_group" "main" {
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

# --- NSGs (kept as raw resources) ---

resource "azurerm_network_security_group" "ingress" {
  name                = local.names.ingress_nsg
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_network_security_group" "container_apps" {
  name                = local.names.container_apps_nsg
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = local.names.private_endpoint_nsg
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

# --- NSG Rules (kept as raw resources) ---

resource "azurerm_network_security_rule" "ingress_allow_https" {
  name                        = "allow-https-from-internet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.ingress.name
}

resource "azurerm_network_security_rule" "ingress_allow_http" {
  name                        = "allow-http-from-internet"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.ingress.name
}

resource "azurerm_network_security_rule" "ingress_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.ingress.name
}

resource "azurerm_network_security_rule" "container_apps_allow_ingress_subnet" {
  name                        = "allow-ingress-subnet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443", "8080", "8081", "8082"]
  source_address_prefix       = local.cidr.ingress
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.container_apps.name
}

resource "azurerm_network_security_rule" "container_apps_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.container_apps.name
}

resource "azurerm_network_security_rule" "private_endpoints_allow_container_apps" {
  name                        = "allow-container-apps-subnet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["443", "10255", "1433"]
  source_address_prefix       = local.cidr.container_apps
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.private_endpoints.name
}

resource "azurerm_network_security_rule" "private_endpoints_deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.private_endpoints.name
}

# --- VNet + Subnets + Peering via AVM ---

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.17"

  name             = local.names.vnet
  location         = azurerm_resource_group.main.location
  parent_id        = azurerm_resource_group.main.id
  address_space    = [local.cidr.vnet]
  enable_telemetry = false
  tags             = local.tags

  subnets = {
    "ingress" = {
      name             = local.names.ingress_subnet
      address_prefixes = [local.cidr.ingress]
      network_security_group = {
        id = azurerm_network_security_group.ingress.id
      }
    }
    "container_apps" = {
      name             = local.names.container_apps_subnet
      address_prefixes = [local.cidr.container_apps]
      delegations = [{
        name = "container-apps-internal"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }]
      network_security_group = {
        id = azurerm_network_security_group.container_apps.id
      }
    }
    "private_endpoints" = {
      name             = local.names.private_endpoint_subnet
      address_prefixes = [local.cidr.private_endpoints]
      network_security_group = {
        id = azurerm_network_security_group.private_endpoints.id
      }
    }
  }

  peerings = var.hub_vnet_name != "" ? {
    "spoke-to-hub" = {
      name                               = "${local.prefix}-to-hub"
      remote_virtual_network_resource_id = data.azurerm_virtual_network.hub[0].id
      allow_virtual_network_access       = true
      allow_forwarded_traffic            = true
      allow_gateway_transit              = false
      use_remote_gateways                = false
    }
  } : {}
}

data "azurerm_virtual_network" "hub" {
  count               = var.hub_vnet_name != "" ? 1 : 0
  provider            = azurerm.hub
  name                = var.hub_vnet_name
  resource_group_name = var.hub_resource_group_name
}
