# Environment Configuration
environment = "prod"
location    = "UK South"
owner       = "Jay@hadandhez.co.uk"
cost_center = "IT-Infrastructure"

# Monitoring Configuration
admin_email_address = "Jay@hadandhez.co.uk"
webhook_uri        = ""

# Network Configuration
vnet_address_space     = ["10.0.0.0/16"]
enable_ddos_protection = true
enable_flow_logs      = true

# AKS Configuration - FIXED FOR SMALL CLUSTER
kubernetes_version      = "1.32.0"
node_count             = 1                    # CHANGED: 1 instead of 3
node_vm_size           = "Standard_B1s"       # CHANGED: B1s (1 vCPU) instead of B2s
max_pods_per_node      = 10                   # REDUCED: 10 instead of 30
private_cluster_enabled = true

# Security Configuration
admin_group_object_ids = [
  "a92fe8ef-c3bf-47c1-9a23-264dbb61f5ca"
]

authorized_ip_ranges = []

# Additional Resource Tags
common_tags = {
  BusinessUnit = "Technology"
  Application  = "Container Platform"
  Criticality  = "High"
  Owner        = "Jay@hadandhez.co.uk"
  Project      = "AKS-Production"
  CostCenter   = "IT-Infrastructure"
}