# =============================================================================
# modules/monitoring/variables.tf
# =============================================================================

# Core Configuration
variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "aks_cluster_id" {
  description = "ID of the AKS cluster to monitor"
  type        = string
}

# Log Analytics Workspace
variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 90
}

variable "daily_quota_gb" {
  description = "Daily quota for Log Analytics in GB"
  type        = number
  default     = 10
}

# Application Insights
variable "app_insights_retention" {
  description = "Application Insights data retention in days"
  type        = number
  default     = 90
}

variable "sampling_percentage" {
  description = "Percentage of telemetry items to sample"
  type        = number
  default     = 100
}

# Alerting Configuration
variable "email_receivers" {
  description = "List of email receivers for alerts"
  type = list(object({
    name  = string
    address = string
  }))
  default = []
}

variable "webhook_receivers" {
  description = "List of webhook receivers for alerts"
  type = list(object({
    name = string
    uri  = string
  }))
  default = []
}

# AKS Diagnostic Settings
variable "aks_log_categories" {
  description = "List of AKS log categories to enable"
  type        = list(string)
  default = [
    "kube-apiserver",
    "kube-audit",
    "kube-audit-admin",
    "kube-controller-manager",
    "kube-scheduler",
    "cluster-autoscaler",
    "guard"
  ]
}

variable "aks_metrics" {
  description = "AKS metrics to collect"
  type = list(object({
    category = string
    enabled  = bool
  }))
  default = [
    {
      category = "AllMetrics"
      enabled  = true
    }
  ]
}

# Alert Rules Configuration
variable "aks_query_alerts" {
  description = "Configuration for scheduled query alert rules"
  type = map(object({
    description           = string
    severity             = number
    enabled              = bool
    evaluation_frequency = string
    window_duration      = string
    query                = string
    time_aggregation     = string
    threshold            = number
    operator             = string
    min_failing_periods  = number
    evaluation_periods   = number
  }))
  default = {
    "security-events" = {
      description           = "Alert on suspicious security events"
      severity             = 1
      enabled              = true
      evaluation_frequency = "PT5M"
      window_duration      = "PT10M"
      query                = <<-EOT
        SecurityEvent
        | where EventID in (4625, 4648, 4719, 4964)
        | summarize count() by bin(TimeGenerated, 5m)
        | where count_ > 10
      EOT
      time_aggregation     = "Count"
      threshold            = 1
      operator             = "GreaterThanOrEqual"
      min_failing_periods  = 1
      evaluation_periods   = 1
    }
  }
}

variable "aks_metric_alerts" {
  description = "Configuration for metric alert rules"
  type = map(object({
    description     = string
    severity       = number
    enabled        = bool
    frequency      = string
    window_size    = string
    metric_namespace = string
    metric_name    = string
    aggregation    = string
    operator       = string
    threshold      = number
    dimensions     = list(object({
      name     = string
      operator = string
      values   = list(string)
    }))
  }))
  default = {
    "node-cpu" = {
      description     = "Alert when AKS node CPU usage is high"
      severity       = 2
      enabled        = true
      frequency      = "PT1M"
      window_size    = "PT5M"
      metric_namespace = "Microsoft.ContainerService/managedClusters"
      metric_name    = "node_cpu_usage_percentage"
      aggregation    = "Average"
      operator       = "GreaterThan"
      threshold      = 80
      dimensions     = [
        {
          name     = "node"
          operator = "Include"
          values   = ["*"]
        }
      ]
    }
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}