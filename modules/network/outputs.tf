output "vnet_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Subnet IDs keyed by subnet name."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "nsg_ids" {
  description = "Network security group IDs keyed by subnet name."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}
