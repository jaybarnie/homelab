# =============================================================================
# Security Module - Key Vault & Identity Management
# =============================================================================

data "azurerm_client_config" "current" {}

# Random suffix for Key Vault name (must be globally unique)
resource "random_string" "keyvault_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Key Vault
resource "azurerm_key_vault" "main" {
name = "${substr(replace(var.name_prefix, "-", ""), 0, 15)}kv${random_string.keyvault_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Security settings
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  enable_rbac_authorization      = true
  purge_protection_enabled       = true
  soft_delete_retention_days     = 90
  public_network_access_enabled  = true

  # Network access
network_acls {
  default_action = "Deny"
  bypass         = "AzureServices"
  ip_rules       = [
    "81.106.56.218/32",
    "100.108.156.38/32",
    "100.108.0.0/16"
  ]
}

  tags = var.tags
}

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  name                = "${var.name_prefix}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_ids["private_endpoints"]

  private_service_connection {
    name                           = "${var.name_prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids["key_vault"]]
  }

  tags = var.tags
}

# User-assigned managed identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.name_prefix}-aks-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Key Vault access for AKS managed identity
resource "azurerm_role_assignment" "aks_keyvault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Key Vault access for admin groups
resource "azurerm_role_assignment" "admin_keyvault_administrator" {
  count                = length(var.admin_group_object_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_group_object_ids[count.index]
}

# Key Vault access for current user/service principal
resource "azurerm_role_assignment" "current_user_keyvault_administrator" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Key Vault secrets for cluster configuration
resource "azurerm_key_vault_secret" "cluster_admin_password" {
  name         = "cluster-admin-password"
  value        = random_password.cluster_admin.result
  key_vault_id = azurerm_key_vault.main.id
  content_type = "password"
  
  tags = merge(var.tags, {
    Purpose = "AKS Cluster Administration"
  })

  depends_on = [azurerm_role_assignment.current_user_keyvault_administrator]
}

resource "random_password" "cluster_admin" {
  length  = 32
  special = true
}

# TLS certificate for ingress
resource "azurerm_key_vault_certificate" "ingress_tls" {
  name         = "ingress-tls-cert"
  key_vault_id = azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=${var.name_prefix}.hadandhed.com"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = [
          "${var.name_prefix}.hadandhed.com",
          "*.${var.name_prefix}.hadandhed.com"
        ]
      }
    }
  }

  tags = var.tags
  depends_on = [azurerm_role_assignment.current_user_keyvault_administrator]
}

# Azure Security Center enablement
resource "azurerm_security_center_subscription_pricing" "key_vault" {
  tier          = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "kubernetes" {
  tier          = "Standard"
  resource_type = "KubernetesService"
}