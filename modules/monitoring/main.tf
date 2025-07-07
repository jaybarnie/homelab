# =============================================================================
# modules/monitoring/main.tf
# =============================================================================

# Log Analytics Workspace with improved naming and settings
resource "azurerm_log_analytics_workspace" "main" {
  name                = lower("${var.name_prefix}-law-${var.environment}")
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.daily_quota_gb
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = merge(var.tags, {
    "MonitoringComponent" = "LogAnalytics"
  })
}

# Container Insights Solution with dependency on workspace
resource "azurerm_log_analytics_solution" "containers" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = merge(var.tags, {
    "MonitoringSolution" = "ContainerInsights"
  })

  depends_on = [azurerm_log_analytics_workspace.main]
}

# Application Insights with workspace integration
resource "azurerm_application_insights" "main" {
  name                = lower("${var.name_prefix}-ai-${var.environment}")
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  retention_in_days   = var.app_insights_retention
  sampling_percentage = var.sampling_percentage

  tags = merge(var.tags, {
    "MonitoringComponent" = "ApplicationInsights"
  })

  depends_on = [azurerm_log_analytics_workspace.main]
}

# Enhanced Action Group with multiple receivers
resource "azurerm_monitor_action_group" "main" {
  name                = lower("${var.name_prefix}-ag-${var.environment}")
  resource_group_name = var.resource_group_name
  short_name          = "aksalerts"
  enabled             = true

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.address
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers
    content {
      name        = webhook_receiver.value.name
      service_uri = webhook_receiver.value.uri
    }
  }

  tags = merge(var.tags, {
    "MonitoringComponent" = "ActionGroup"
  })
}

# FIXED: Comprehensive AKS Diagnostic Settings - CONDITIONAL
resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = var.aks_cluster_id != null && var.aks_cluster_id != "" ? 1 : 0

  name                       = lower("${var.name_prefix}-aks-diag-${var.environment}")
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = var.aks_log_categories
    content {
      category = enabled_log.value
    }
  }

  # FIXED: Replace deprecated metric block with enabled_metric
  dynamic "enabled_metric" {
    for_each = var.aks_metrics
    content {
      category = enabled_metric.value.category
    }
  }

  lifecycle {
    ignore_changes = [log_analytics_destination_type] # Required for AKS integration
  }

  depends_on = [azurerm_log_analytics_workspace.main]
}

# FIXED: Smart Alert Rules with dynamic thresholds - CONDITIONAL
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "aks_alerts" {
  for_each = var.aks_cluster_id != null && var.aks_cluster_id != "" ? var.aks_query_alerts : {}

  name                = lower("${var.name_prefix}-${each.key}-alert")
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = each.value.description
  severity            = each.value.severity
  enabled             = each.value.enabled
  
  evaluation_frequency = each.value.evaluation_frequency
  window_duration     = each.value.window_duration
  scopes              = [azurerm_log_analytics_workspace.main.id]
  
  criteria {
    query                   = each.value.query
    time_aggregation_method = each.value.time_aggregation
    threshold              = each.value.threshold
    operator               = each.value.operator
    
    failing_periods {
      minimum_failing_periods_to_trigger_alert = each.value.min_failing_periods
      number_of_evaluation_periods             = each.value.evaluation_periods
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.main.id]
  }

  tags = merge(var.tags, {
    "AlertType" = "ScheduledQuery"
  })

  depends_on = [
    azurerm_log_analytics_workspace.main,
    azurerm_monitor_action_group.main
  ]
}

# FIXED: Metric Alerts for AKS - CONDITIONAL
resource "azurerm_monitor_metric_alert" "aks_metrics" {
  for_each = var.aks_cluster_id != null && var.aks_cluster_id != "" ? var.aks_metric_alerts : {}

  name                = lower("${var.name_prefix}-${each.key}-alert")
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_cluster_id]
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  enabled             = each.value.enabled

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold

    dynamic "dimension" {
      for_each = each.value.dimensions
      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = merge(var.tags, {
    "AlertType" = "Metric"
  })

  depends_on = [azurerm_monitor_action_group.main]
}