# =============================================================================
# modules/monitoring/outputs.tf
# =============================================================================

# Log Analytics Workspace Outputs
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

# ADD THIS MISSING OUTPUT
output "log_analytics_workspace_resource_id" {
  description = "The resource ID of the Log Analytics Workspace (same as ID)"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_workspace_id" {
  description = "The Workspace ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_analytics_workspace_primary_shared_key" {
  description = "The Primary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_primary_key" {
  description = "The Primary key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

# Application Insights Outputs
output "application_insights_id" {
  description = "The ID of the Application Insights resource"
  value       = azurerm_application_insights.main.id
}

output "application_insights_name" {
  description = "The name of the Application Insights resource"
  value       = azurerm_application_insights.main.name
}

output "application_insights_app_id" {
  description = "The App ID of the Application Insights resource"
  value       = azurerm_application_insights.main.app_id
}

output "application_insights_instrumentation_key" {
  description = "The Instrumentation Key of the Application Insights resource"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The Connection String of the Application Insights resource"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# Action Group Outputs
output "action_group_id" {
  description = "The ID of the Action Group"
  value       = azurerm_monitor_action_group.main.id
}

output "action_group_name" {
  description = "The name of the Action Group"
  value       = azurerm_monitor_action_group.main.name
}

# Monitoring Solutions Outputs
output "container_insights_solution_id" {
  description = "The ID of the Container Insights solution"
  value       = try(azurerm_log_analytics_solution.containers.id, null)
}

# Diagnostic Settings Output
output "aks_diagnostic_setting_id" {
  description = "The ID of the AKS diagnostic setting"
  value       = try(azurerm_monitor_diagnostic_setting.aks[0].id, null)
}

# Alert Rules Outputs
output "metric_alert_ids" {
  description = "Map of metric alert names to their IDs"
  value       = { for k, v in azurerm_monitor_metric_alert.aks_metrics : k => v.id }
}

output "query_alert_ids" {
  description = "Map of query alert names to their IDs"
  value       = { for k, v in azurerm_monitor_scheduled_query_rules_alert_v2.aks_alerts : k => v.id }
}

# Combined Monitoring Outputs
output "monitoring_tools" {
  description = "Map containing all monitoring tool endpoints and identifiers"
  value = {
    log_analytics = {
      workspace_id  = azurerm_log_analytics_workspace.main.workspace_id
      portal_url   = "https://portal.azure.com/#blade/Microsoft_OperationsManagementSuite_Workspace/WorkspaceOverviewBlade/id/${azurerm_log_analytics_workspace.main.id}"
    }
    application_insights = {
      app_id       = azurerm_application_insights.main.app_id
      portal_url   = "https://portal.azure.com/#blade/AppInsightsExtension/QuickPulseBladeV2/ComponentId/${azurerm_application_insights.main.id}"
    }
  }
}