output "resource_group_name" {
  description = "Resource group holding this environment."
  value       = module.resource_group.name
}

output "storage_account_name" {
  description = "Storage account name."
  value       = module.storage_account.name
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint."
  value       = module.storage_account.primary_blob_endpoint
}

output "aks_cluster_name" {
  description = "AKS cluster name, null when aks_enabled is false."
  value       = var.aks_enabled ? module.aks[0].name : null
}

output "aks_api_fqdn" {
  description = "API server FQDN, null when aks_enabled is false."
  value       = var.aks_enabled ? module.aks[0].fqdn : null
}
