# =============================================================================
# Networking Module - Production AKS
# =============================================================================

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


# Network Watcher (required for flow logs)
resource "azurerm_network_watcher" "default" {
  name                = "${var.name_prefix}-network-watcher"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Storage Account for Flow Logs - FIXED name length and characters
resource "azurerm_storage_account" "logsa" {
  name                     = "${replace(var.name_prefix, "-", "")}logsa"  # Remove hyphens
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

# If the name is still too long, use this instead:
# resource "azurerm_storage_account" "logsa" {
#   name                     = "logs${substr(replace(var.name_prefix, "-", ""), 0, 15)}"
#   resource_group_name      = var.resource_group_name
#   location                 = var.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   tags = var.tags
# }
# AKS System Subnet
resource "azurerm_subnet" "aks_system" {
  name                 = "${var.name_prefix}-aks-system-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets["aks_system"]]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]  # ADD THIS
}

# AKS User Subnet
resource "azurerm_subnet" "aks_user" {
  name                 = "${var.name_prefix}-aks-user-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets["aks_user"]]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]  # ADD THIS
}

# Private Endpoints Subnet
resource "azurerm_subnet" "private_endpoints" {
  name                 = "${var.name_prefix}-private-endpoints-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets["private_endpoints"]]
}

# Network Security Group for AKS System
resource "azurerm_network_security_group" "aks_system" {
  name                = "${var.name_prefix}-aks-system-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow Azure Load Balancer
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Allow HTTPS outbound
  security_rule {
    name                       = "AllowHTTPSOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# NSG Flow Logs
resource "azurerm_network_watcher_flow_log" "nsg_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name                       = "${var.name_prefix}-nsg-flowlog"
  network_watcher_name      = azurerm_network_watcher.default.name
  resource_group_name       = var.resource_group_name
  target_resource_id        = azurerm_network_security_group.aks_system.id
  storage_account_id        = azurerm_storage_account.logsa.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 90
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.log_analytics_workspace_workspace_id
    workspace_resource_id = var.log_analytics_workspace_resource_id
    workspace_region      = var.location
    interval_in_minutes   = 60
  }

  tags = var.tags

  depends_on = [
    azurerm_network_security_group.aks_system,
    azurerm_network_watcher.default
  ]
}

# NSG Association to Subnet
resource "azurerm_subnet_network_security_group_association" "aks_system" {
  subnet_id                 = azurerm_subnet.aks_system.id
  network_security_group_id = azurerm_network_security_group.aks_system.id
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone for Blob Storage
resource "azurerm_private_dns_zone" "blob_storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone for Container Registry
resource "azurerm_private_dns_zone" "container_registry" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
