variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "UK South"
}

variable "company_name" {
  description = "Company name for naming convention"
  type        = string
  default     = "hadandhed"
}

variable "project_name" {
  description = "Project name for naming convention"
  type        = string
  default     = "aks"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Network Variables
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable NSG flow logs"
  type        = bool
  default     = true
}

# AKS Variables
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31.8"
}

variable "node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "VM size for nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
  default     = 30
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "authorized_ip_ranges" {
  description = "Authorized IP ranges for API server"
  type        = list(string)
  default     = []
}

variable "admin_group_object_ids" {
  description = "Object IDs of Azure AD groups with admin access"
  type        = list(string)
}

variable "admin_email_address" {
  description = "Email address for alert notifications"
  type        = string
  default     = "platform.team@hadandhez.co.uk"
}

variable "webhook_uri" {
  description = "Webhook URI for alert notifications (Slack/Teams)"
  type        = string
  default     = ""
}
