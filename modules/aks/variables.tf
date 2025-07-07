variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Network configuration
variable "vnet_subnet_id" {
  description = "ID of the subnet for AKS system nodes"
  type        = string
}

variable "user_subnet_id" {
  description = "ID of the subnet for AKS user nodes"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"
}

# Cluster configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33"
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

# Node configuration
variable "system_node_count" {
  description = "Number of system nodes"
  type        = number
  default     = 1
}

variable "system_node_vm_size" {
  description = "VM size for system nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Initial number of user nodes"
  type        = number
  default     = 1
}

variable "node_vm_size" {
  description = "VM size for user nodes"
  type        = string
  default     = "Standard_B1s"
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
  default     = 2
}

# Security configuration
variable "admin_group_object_ids" {
  description = "Object IDs of Azure AD groups with admin access"
  type        = list(string)
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "container_registry_id" {
  description = "ID of the Container Registry"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}