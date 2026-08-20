locals {
  tags = merge(module.naming.tags, var.extra_tags)
}

module "naming" {
  source = "git::https://github.com/linubah/dev-qa-azure-infrastructure.git//modules/naming?ref=v1.1.0"

  brand         = var.brand
  environment   = var.environment
  location      = var.location
  location_code = var.location_code
  workload      = var.workload
  unique_suffix = var.unique_suffix
}

module "resource_group" {
  source = "git::https://github.com/linubah/dev-qa-azure-infrastructure.git//modules/resource_group?ref=v1.1.0"

  name     = module.naming.resource_group
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "git::https://github.com/linubah/dev-qa-azure-infrastructure.git//modules/network?ref=v1.1.0"
  count  = var.aks_enabled ? 1 : 0

  name                = module.naming.vnet
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = var.vnet_address_space

  subnets = {
    aks = {
      address_prefix    = var.aks_subnet_prefix
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
  }

  tags = local.tags
}

module "storage_account" {
  source = "git::https://github.com/linubah/dev-qa-azure-infrastructure.git//modules/storage_account?ref=v1.1.0"

  name                = module.naming.storage_account
  resource_group_name = module.resource_group.name
  location            = var.location

  replication_type  = var.storage_replication_type
  containers        = var.storage_containers
  allowed_ip_ranges = var.allowed_ip_ranges

  tags = local.tags
}

module "aks" {
  source = "git::https://github.com/linubah/dev-qa-azure-infrastructure.git//modules/aks?ref=v1.1.0"
  count  = var.aks_enabled ? 1 : 0

  name                = module.naming.aks
  resource_group_name = module.resource_group.name
  location            = var.location

  node_pool_default = {
    vm_size        = var.aks_node_size
    node_count     = var.aks_node_count
    vnet_subnet_id = module.network[0].subnet_ids["aks"]
  }

  private_cluster_enabled = var.aks_private_cluster
  authorized_ip_ranges    = var.aks_authorized_ip_ranges

  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  network_policy      = var.aks_network_policy

  local_account_disabled = var.aks_local_account_disabled
  azure_rbac_enabled     = true
  admin_group_object_ids = var.aks_admin_group_object_ids

  workload_identity_enabled = true
  azure_policy_enabled      = true

  upgrade_channel = var.aks_upgrade_channel

  tags = local.tags
}
