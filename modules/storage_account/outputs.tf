output "id" {
  description = "Storage account ID."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Storage account name."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary Data Lake Gen2 endpoint."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "identity_principal_id" {
  description = "System-assigned managed identity principal ID."
  value       = azurerm_storage_account.this.identity[0].principal_id
}

output "container_names" {
  description = "Names of created blob containers."
  value       = [for c in azurerm_storage_container.this : c.name]
}
