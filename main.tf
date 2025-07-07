terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.34"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.3"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.32"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
 # resource_provider_registrations = "none"  # FIXED: was skip_provider_registration = no
}

provider "azuread" {}

# Local variables for common configurations
locals {
  # Common tags applied to all resources
  common_tags = merge(var.common_tags, {
    Project          = "AKS-Production"
    Company          = "Hadandhez-Ltd"
    Environment      = var.environment
    ManagedBy        = "Terraform"
    Owner            = var.owner
    CostCenter       = var.cost_center
    CreatedDate      = formatdate("YYYY-MM-DD", timestamp())
  })
  # Naming convention
  name_prefix = "${var.company_name}-${var.project_name}-${var.environment}"
  
  # Network configuration
  network_config = {
    address_space = var.vnet_address_space
    subnets = {
      aks_system        = cidrsubnet(var.vnet_address_space[0], 8, 1)  # /24
      aks_user          = cidrsubnet(var.vnet_address_space[0], 8, 2)  # /24
      private_endpoints = cidrsubnet(var.vnet_address_space[0], 8, 3)  # /24
      application_gateway = cidrsubnet(var.vnet_address_space[0], 8, 4)  # /24
      bastion           = cidrsubnet(var.vnet_address_space[0], 8, 5)  # /24
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# Monitoring Module (create first for Log Analytics workspace)
module "monitoring" {
  source = "./modules/monitoring"
  
  # Required arguments
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  location           = var.location
  name_prefix        = local.name_prefix
  environment        = var.environment  # Added required environment parameter
  
  # Cluster ID (can be updated later)
  aks_cluster_id     = null  # FIXED: removed quotes from "null"
  
  # Alert receivers configuration (updated to match module's expected structure)
  email_receivers = [{
    name    = "admin-email"
    address = var.admin_email_address
  }]
  
  webhook_receivers = var.webhook_uri != "" ? [{
    name = "webhook-alert"
    uri  = var.webhook_uri
  }] : []
  
  tags = local.common_tags
  
  # Optional parameters with defaults (add if you need to override defaults)
  # log_retention_days      = 30
  # daily_quota_gb         = 1
  # app_insights_retention = 90
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = var.location
  name_prefix        = local.name_prefix
  
  vnet_address_space = local.network_config.address_space
  subnets           = local.network_config.subnets
  
  enable_flow_logs      = var.enable_flow_logs
  
  # Pass Log Analytics workspace for flow logs
log_analytics_workspace_id          = module.monitoring.log_analytics_workspace_id
  log_analytics_workspace_resource_id = module.monitoring.log_analytics_workspace_resource_id
  log_analytics_workspace_workspace_id = module.monitoring.log_analytics_workspace_workspace_id  # ADD THIS LINE
  
  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = var.location
  name_prefix        = local.name_prefix
  
  vnet_id                    = module.networking.vnet_id
  subnet_ids                 = module.networking.subnet_ids
  private_dns_zone_ids       = module.networking.private_dns_zones
  
  admin_group_object_ids     = var.admin_group_object_ids
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  
  tags = local.common_tags
  
  depends_on = [module.networking, module.monitoring]
}

# Storage Module
module "storage" {
  source = "./modules/storage"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = var.location
  name_prefix        = local.name_prefix
  
  vnet_id                    = module.networking.vnet_id
  subnet_ids                 = module.networking.subnet_ids
  private_dns_zone_ids       = module.networking.private_dns_zones
  key_vault_id               = module.security.key_vault_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  
  tags = local.common_tags
  
  depends_on = [module.networking, module.security]
}

# AKS Module
module "aks" {
  source = "./modules/aks"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = var.location
  name_prefix        = local.name_prefix
  environment        = var.environment
  
  # Network configuration
  vnet_subnet_id = module.networking.subnet_ids["aks_system"]
  user_subnet_id = module.networking.subnet_ids["aks_user"]
  vnet_id        = module.networking.vnet_id
  
  # Security configuration
  container_registry_id    = module.storage.container_registry_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  
  # Cluster configuration
  kubernetes_version    = var.kubernetes_version
  node_count           = var.node_count
  node_vm_size         = var.node_vm_size
  max_pods_per_node    = var.max_pods_per_node
  
  # Security settings
  private_cluster_enabled = var.private_cluster_enabled
  authorized_ip_ranges   = var.authorized_ip_ranges
  admin_group_object_ids = var.admin_group_object_ids
  
  tags = local.common_tags
  
  depends_on = [
    module.networking,
    module.security,
    module.storage
  ]
}