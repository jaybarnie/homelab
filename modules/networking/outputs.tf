output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    aks_system        = azurerm_subnet.aks_system.id
    aks_user          = azurerm_subnet.aks_user.id
    private_endpoints = azurerm_subnet.private_endpoints.id
  }
}

output "private_dns_zones" {
  description = "Map of private DNS zone IDs"
  value = {
    key_vault          = azurerm_private_dns_zone.key_vault.id
    container_registry = azurerm_private_dns_zone.container_registry.id
    blob_storage       = azurerm_private_dns_zone.blob_storage.id
  }
}



output "private_dns_zone_names" {
  description = "Map of private DNS zone names"
  value = {
    key_vault          = azurerm_private_dns_zone.key_vault.name
    container_registry = azurerm_private_dns_zone.container_registry.name
  }
}

# REMOVED INVALID OUTPUT - Log Analytics workspace doesn't exist in networking module
# The monitoring module handles all Log Analytics outputs
# output "log_analytics_workspace_resource_id" {
#   description = "The Azure Resource ID of the Log Analytics workspace"
#   value       = azurerm_log_analytics_workspace
# }