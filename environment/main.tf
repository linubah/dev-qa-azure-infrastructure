locals {
  tags = merge(module.naming.tags, var.extra_tags)
}

module "naming" {
  source = "git::https://github.com/linubah/dev-qa-azure-infrastructure.git//modules/naming?ref=v1.0.0"

  brand         = var.brand
  environment   = var.environment
  location      = var.location
  location_code = var.location_code
  workload      = var.workload
  unique_suffix = var.unique_suffix
}

module "resource_group" {
  source = "git::https://github.com/linubah/dev-qa-azure-infrastructure.git//modules/resource_group?ref=v1.0.0"

  name     = module.naming.resource_group
  location = var.location
  tags     = local.tags
}

module "key_vault" {
  source = "git::https://github.com/linubah/dev-qa-azure-infrastructure.git//modules/key_vault?ref=v1.0.0"

  name                = module.naming.key_vault
  resource_group_name = module.resource_group.name
  location            = var.location

  sku                        = var.key_vault_sku
  rbac_authorization_enabled = var.key_vault_rbac_authorization
  purge_protection_enabled   = var.key_vault_purge_protection
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days

  allowed_ip_ranges = var.allowed_ip_ranges
  role_assignments  = var.key_vault_role_assignments

  tags = local.tags
}
