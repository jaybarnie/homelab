# =============================================================================
# AKS Module - Production Kubernetes 1.31.8 (Fixed)
# =============================================================================
data "azurerm_client_config" "current" {}

# Public IP for AKS outbound traffic
resource "azurerm_public_ip" "aks_outbound" {
  name                = "${var.name_prefix}-aks-outbound-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                = "Standard"
  zones              = ["1", "2", "3"]
  
  tags = var.tags
}

# AKS Cluster - REMOVED depends_on to break the cycle
resource "azurerm_kubernetes_cluster" "main" {
  name                      = "${var.name_prefix}-aks"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "${var.name_prefix}-aks"
  kubernetes_version        = var.kubernetes_version
  private_cluster_enabled   = var.private_cluster_enabled

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # OIDC Issuer for Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # System node pool (FIXED availability_zones syntax)
  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = var.system_node_vm_size
    type                = "VirtualMachineScaleSets"
    zones               = ["1", "2", "3"]  # FIXED: was availability_zones
    max_pods            = var.max_pods_per_node
    only_critical_addons_enabled = true
    os_disk_size_gb     = 100
    os_disk_type        = "Managed"
    vnet_subnet_id      = var.vnet_subnet_id
    auto_scaling_enabled = false  
    min_count          = var.system_node_count
    max_count          = var.system_node_count 
    
    # System workloads only
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = var.environment
      "nodepoolos"       = "linux"
      "app"             = "system-apps"
    }
    os_sku = "Ubuntu"
    upgrade_settings {
      max_surge = "10%"
    }
    tags = var.tags
  }

  # Network profile
  network_profile {
    network_plugin      = "azure"
    network_policy      = "azure"
    dns_service_ip     = cidrhost(var.service_cidr, 10)
    service_cidr       = var.service_cidr
    outbound_type      = "loadBalancer"
    load_balancer_sku  = "standard"
    load_balancer_profile {
      outbound_ip_address_ids = [azurerm_public_ip.aks_outbound.id]
    }
  }

  # Azure AD integration
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  # Monitoring
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Auto-upgrade

  # Maintenance windows
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "00:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "04:00"
    utc_offset  = "+00:00"
  }

  # Security
  run_command_enabled = false
  
  # Image cleaner
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  tags = var.tags

  # REMOVED depends_on - this was causing the cycle!
  # depends_on = [
  #   azurerm_role_assignment.aks_network_contributor,
  #   azurerm_role_assignment.aks_acr_pull
  # ]

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# User node pool for application workloads (FIXED)
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = var.node_vm_size
  node_count           = var.node_count
  zones                = ["1", "2", "3"]  # FIXED: was availability_zones
  max_pods             = var.max_pods_per_node
  os_disk_size_gb      = 100
  os_disk_type         = "Ephemeral"
  vnet_subnet_id       = var.user_subnet_id
  priority             = "Spot"
  eviction_policy      = "Delete"
  auto_scaling_enabled = false
 # min_count           = var.node_count
 # max_count           = var.node_count 
  mode                = "User"

  node_labels = {
    "nodepool-type"    = "user"
    "environment"      = var.environment
    "nodepoolos"       = "linux"
    "app"             = "user-apps"
  }
  os_sku = "Ubuntu"
# REMOVE THIS ENTIRE BLOCK:
# upgrade_settings {
#   max_surge = "33%"
# }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Role assignments - these will be created AFTER the cluster
# Terraform automatically handles the dependency because they reference cluster attributes
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# User-assigned managed identity for workload identity
resource "azurerm_user_assigned_identity" "aks_workload" {
  name                = "${var.name_prefix}-aks-workload-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Federated identity credential
resource "azurerm_federated_identity_credential" "aks_workload" {
  name                = "${var.name_prefix}-aks-workload-credential"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.aks_workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:kube-system:workload-identity-sa"
}