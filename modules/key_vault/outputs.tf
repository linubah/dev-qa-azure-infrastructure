output "id" {
  description = "Key Vault ID."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "Key Vault DNS endpoint."
  value       = azurerm_key_vault.this.vault_uri
}

output "tenant_id" {
  description = "Entra tenant the vault authenticates against."
  value       = azurerm_key_vault.this.tenant_id
}

output "role_assignment_ids" {
  description = "Role assignments created on the vault, keyed as supplied."
  value       = { for k, v in azurerm_role_assignment.this : k => v.id }
}
