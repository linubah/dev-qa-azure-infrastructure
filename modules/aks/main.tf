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

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_size
    os_disk_size_gb      = var.node_os_disk_size_gb
    vnet_subnet_id       = var.vnet_subnet_id
    auto_scaling_enabled = var.auto_scaling_enabled
    node_count           = var.node_count
    min_count            = var.auto_scaling_enabled ? var.min_node_count : null
    max_count            = var.auto_scaling_enabled ? var.max_node_count : null

    # Hardening: no public IPs on nodes, host-level OS patching left to AKS.
    node_public_ip_enabled       = false
    only_critical_addons_enabled = var.only_critical_addons_enabled
    orchestrator_version         = var.kubernetes_version
    max_pods                     = var.max_pods_per_node
    host_encryption_enabled      = var.host_encryption_enabled
    os_disk_type                 = var.os_disk_type

    upgrade_settings {
      max_surge = "10%"
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
