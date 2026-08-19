resource "azurerm_storage_account" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = true

  shared_access_key_enabled     = var.shared_access_key_enabled
  public_network_access_enabled = var.public_network_access_enabled

  identity {
    type = "SystemAssigned"
  }

  blob_properties {
    versioning_enabled = var.versioning_enabled

    # Azure rejects days = 0; the block must be absent to disable retention.
    dynamic "delete_retention_policy" {
      for_each = var.blob_retention_days > 0 ? [1] : []
      content {
        days = var.blob_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.blob_retention_days > 0 ? [1] : []
      content {
        days = var.blob_retention_days
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.allowed_ip_ranges == null && length(var.allowed_subnet_ids) == 0 ? [] : [1]
    content {
      default_action             = var.network_rules_default_action
      ip_rules                   = coalesce(var.allowed_ip_ranges, [])
      virtual_network_subnet_ids = var.allowed_subnet_ids
      bypass                     = var.network_rules_bypass
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.access_type
}
