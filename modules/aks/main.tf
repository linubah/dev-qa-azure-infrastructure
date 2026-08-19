locals {
  # Overlay mode carries its own pod CIDR; kubenet/azure-classic must not set one.
  use_pod_cidr = var.network_plugin_mode == "overlay"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = coalesce(var.dns_prefix, var.name)
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  # Entra ID as the only auth path - no static admin kubeconfig to leak.
  local_account_disabled            = var.local_account_disabled
  role_based_access_control_enabled = true

  private_cluster_enabled = var.private_cluster_enabled

  # Ignored when the cluster is private; the API server has no public IP then.
  api_server_access_profile {
    authorized_ip_ranges = var.private_cluster_enabled ? null : var.authorized_ip_ranges
  }

  # Azure requires exactly one default pool; it cannot be omitted or moved out.
  default_node_pool {
    name    = var.node_pool_default.name
    vm_size = var.node_pool_default.vm_size
    zones   = var.node_pool_default.zones

    auto_scaling_enabled = var.node_pool_default.auto_scaling_enabled
    node_count           = var.node_pool_default.node_count
    min_count            = var.node_pool_default.auto_scaling_enabled ? var.node_pool_default.min_count : null
    max_count            = var.node_pool_default.auto_scaling_enabled ? var.node_pool_default.max_count : null

    os_disk_size_gb = var.node_pool_default.os_disk_size_gb
    os_disk_type    = var.node_pool_default.os_disk_type
    max_pods        = var.node_pool_default.max_pods
    vnet_subnet_id  = var.node_pool_default.vnet_subnet_id

    # Nodes stay off the public internet regardless of what the caller asks for.
    node_public_ip_enabled       = false
    only_critical_addons_enabled = var.node_pool_default.only_critical_addons_enabled
    host_encryption_enabled      = var.node_pool_default.host_encryption_enabled
    orchestrator_version         = var.kubernetes_version

    upgrade_settings {
      max_surge = var.node_pool_default.max_surge
    }

    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = var.azure_rbac_enabled
    admin_group_object_ids = var.admin_group_object_ids
  }

  workload_identity_enabled = var.workload_identity_enabled
  oidc_issuer_enabled       = var.workload_identity_enabled

  # Gatekeeper enforces policy inside the cluster
  azure_policy_enabled = var.azure_policy_enabled

  automatic_upgrade_channel = var.upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = var.secret_rotation_interval
    }
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin == "azure" ? var.network_plugin_mode : null
    network_policy      = var.network_policy
    pod_cidr            = local.use_pod_cidr ? var.pod_cidr : null
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    outbound_type       = var.outbound_type
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id == null ? [] : [1]
    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].node_count,
    ]
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = {
    for k, v in var.additional_node_pools : k => v if v.enabled
  }

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = each.key

  vm_size = each.value.vm_size
  mode    = each.value.mode
  os_type = each.value.os_type
  os_sku  = each.value.os_sku
  zones   = each.value.zones

  auto_scaling_enabled = each.value.auto_scaling_enabled
  node_count           = each.value.node_count
  min_count            = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count            = each.value.auto_scaling_enabled ? each.value.max_count : null

  os_disk_size_gb = each.value.os_disk_size_gb
  os_disk_type    = each.value.os_disk_type
  max_pods        = each.value.max_pods

  priority        = each.value.priority
  eviction_policy = each.value.priority == "Spot" ? each.value.eviction_policy : null
  spot_max_price  = each.value.priority == "Spot" ? each.value.spot_max_price : null

  node_labels = each.value.node_labels
  node_taints = each.value.node_taints

  vnet_subnet_id          = each.value.vnet_subnet_id
  host_encryption_enabled = each.value.host_encryption_enabled
  fips_enabled            = each.value.fips_enabled
  orchestrator_version    = each.value.orchestrator_version
  node_public_ip_enabled  = false

  upgrade_settings {
    max_surge = each.value.max_surge
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}
