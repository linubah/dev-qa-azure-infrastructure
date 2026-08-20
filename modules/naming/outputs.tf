output "resource_group" {
  description = "Resource group name."
  value       = local.names.resource_group
}

output "storage_account" {
  description = "Storage account name. Globally unique, no hyphens."
  value       = local.names.storage_account
}

output "key_vault" {
  description = "Key Vault name. Globally unique."
  value       = local.names.key_vault
}

output "vnet" {
  description = "Virtual network name."
  value       = local.names.vnet
}

output "aks" {
  description = "AKS cluster name."
  value       = local.names.aks
}

output "tags" {
  description = "Tags to merge into every resource in the stack."
  value       = local.tags
}
