# =============================================================================
# modules/storage/outputs.tf
# =============================================================================

output "container_registry_id" {
  description = "ID of the Container Registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server of the Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "cluster_data_storage_account_id" {
  description = "ID of the cluster data storage account"
  value       = azurerm_storage_account.cluster_data.id
}

output "cluster_data_storage_account_name" {
  description = "Name of the cluster data storage account"
  value       = azurerm_storage_account.cluster_data.name
}

output "backup_storage_account_id" {
  description = "ID of the backup storage account"
  value       = azurerm_storage_account.backup.id
}

output "backup_storage_account_name" {
  description = "Name of the backup storage account"
  value       = azurerm_storage_account.backup.name
}

output "recovery_services_vault_id" {
  description = "ID of the Recovery Services Vault"
  value       = azurerm_recovery_services_vault.main.id
}

output "recovery_services_vault_name" {
  description = "Name of the Recovery Services Vault"
  value       = azurerm_recovery_services_vault.main.name
}