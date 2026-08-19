data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  sku_name            = var.sku

  rbac_authorization_enabled = var.rbac_authorization_enabled

  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment

  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.allowed_ip_ranges == null && length(var.allowed_subnet_ids) == 0 ? [] : [1]
    content {
      default_action             = var.network_acls_default_action
      bypass                     = var.network_acls_bypass
      ip_rules                   = coalesce(var.allowed_ip_ranges, [])
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "this" {
  for_each = var.rbac_authorization_enabled ? var.role_assignments : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
