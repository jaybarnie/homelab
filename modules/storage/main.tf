# =============================================================================
# modules/storage/main.tf - MINIMAL WORKING VERSION
# =============================================================================

# Random suffix for storage account names (must be globally unique)
resource "random_string" "storage_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Container Registry - SIMPLIFIED (no deprecated features)
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.name_prefix, "-", "")}acr${random_string.storage_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                = "Premium"
  admin_enabled      = false

  # Security settings
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  # Identity for encryption
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  # Remove encryption and policies for now - get the basic ACR working first
  # You can configure retention/trust policies via Azure CLI after creation:
  # az acr config retention update --registry <name> --status enabled --days 30 --type UntaggedManifests
  # az acr config content-trust update --registry <name> --status enabled
}

# Private endpoint for Container Registry
resource "azurerm_private_endpoint" "acr" {
  name                = "${var.name_prefix}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private_endpoints"]

  private_service_connection {
    name                           = "${var.name_prefix}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids["container_registry"]]
  }

  tags = var.tags
}

# Storage account for cluster data
resource "azurerm_storage_account" "cluster_data" {
name = "${substr(replace(var.name_prefix, "-", ""), 0, 15)}data${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  min_tls_version          = "TLS1_2"

  # Security settings
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Infrastructure encryption
  infrastructure_encryption_enabled = true

  # Identity for encryption
  identity {
    type = "SystemAssigned"
  }

  # Blob properties
  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    change_feed_retention_in_days = 30
    last_access_time_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }
# COMMENT OUT the network_rules block temporarily
# network_rules {
#   default_action             = "Deny"
#   bypass                     = ["AzureServices"]
#   virtual_network_subnet_ids = [var.subnet_ids["aks_system"], var.subnet_ids["aks_user"]]
# }

  tags = var.tags
}

# Private endpoint for Storage Account (blob)
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${var.name_prefix}-storage-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private_endpoints"]

  private_service_connection {
    name                           = "${var.name_prefix}-storage-blob-psc"
    private_connection_resource_id = azurerm_storage_account.cluster_data.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids["blob_storage"]]
  }

  tags = var.tags
}

# Storage containers - FIXED: Use storage_account_id
resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_id    = azurerm_storage_account.cluster_data.id
  container_access_type = "private"
  depends_on = [azurerm_role_assignment.current_user_storage_blob_data_owner]
}

resource "azurerm_storage_container" "configs" {
  name                  = "configs"
  storage_account_id    = azurerm_storage_account.cluster_data.id
  container_access_type = "private"
  depends_on = [azurerm_role_assignment.current_user_storage_blob_data_owner]
}

# Storage account for backup
resource "azurerm_storage_account" "backup" {
name = "${substr(replace(var.name_prefix, "-", ""), 0, 13)}bkp${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  # Security settings
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Infrastructure encryption
  infrastructure_encryption_enabled = true

  # Identity for encryption
  identity {
    type = "SystemAssigned"
  }

  # Blob properties
  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy {
      days = 90
    }

    container_delete_retention_policy {
      days = 90
    }
  }

  # Network rules
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.subnet_ids["aks_system"], var.subnet_ids["aks_user"]]
  }

  tags = var.tags
}

# Recovery Services Vault for backup
resource "azurerm_recovery_services_vault" "main" {
  name                = "${var.name_prefix}-rsv"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                = "Standard"
  
  # Security settings
  storage_mode_type                             = "GeoRedundant"
  cross_region_restore_enabled                  = true
  soft_delete_enabled                          = true
  immutability                                 = "Locked"
  
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Role assignments for storage access
data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "current_user_storage_blob_data_owner" {
  scope                = azurerm_storage_account.cluster_data.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Diagnostic settings for ACR - FIXED: Remove deprecated metric syntax
resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "${var.name_prefix}-acr-diagnostics"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  # REMOVED deprecated metric block - use log_category_types instead if needed
}

# Diagnostic settings for Storage Account - FIXED: Remove deprecated metric syntax
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "${var.name_prefix}-storage-diagnostics"
  target_resource_id         = "${azurerm_storage_account.cluster_data.id}/blobServices/default/"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  # REMOVED deprecated metric blocks
}