variable "name" {
  description = "AKS cluster name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]{0,61}[a-zA-Z0-9]$", var.name))
    error_message = "Cluster name must be 2-63 chars, alphanumeric with hyphens/underscores, starting and ending alphanumeric."
  }
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the API server. Defaults to the cluster name."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version. null tracks the region default."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "Control plane SKU. Free has no uptime SLA."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Free, Standard, or Premium."
  }
}

# --- network security ---

variable "private_cluster_enabled" {
  description = "Give the API server a private endpoint only. Requires private DNS and network line-of-sight from CI."
  type        = bool
  default     = false
}

variable "authorized_ip_ranges" {
  description = "CIDRs allowed to reach the public API server. null leaves it open to the internet."
  type        = list(string)
  default     = null

  validation {
    condition     = var.authorized_ip_ranges == null || alltrue([for c in coalesce(var.authorized_ip_ranges, []) : can(cidrnetmask(c))])
    error_message = "authorized_ip_ranges must contain valid CIDR blocks."
  }
}

variable "network_plugin" {
  description = "CNI plugin."
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_plugin)
    error_message = "network_plugin must be azure, kubenet, or none."
  }
}

variable "network_plugin_mode" {
  description = "Overlay conserves VNet address space by NAT-ing pod IPs."
  type        = string
  default     = "overlay"
}

variable "network_policy" {
  description = "Network policy engine for pod-to-pod traffic control."
  type        = string
  default     = "calico"

  validation {
    condition     = contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "network_policy must be azure, calico, or cilium."
  }
}

variable "pod_cidr" {
  description = "Pod address space when using overlay mode."
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Kubernetes service address space. Must not overlap the VNet."
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "Cluster DNS service IP. Must sit inside service_cidr."
  type        = string
  default     = "10.0.0.10"
}

variable "outbound_type" {
  description = "Egress path for cluster traffic."
  type        = string
  default     = "loadBalancer"
}

# --- identity and access ---

variable "local_account_disabled" {
  description = "Disable static admin kubeconfig so Entra ID is the only auth path."
  type        = bool
  default     = true
}

variable "azure_rbac_enabled" {
  description = "Use Azure RBAC for Kubernetes authorization."
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Entra group object IDs granted cluster-admin."
  type        = list(string)
  default     = []
}

variable "workload_identity_enabled" {
  description = "Enable Entra Workload Identity for pod-level federated credentials."
  type        = bool
  default     = true
}

variable "azure_policy_enabled" {
  description = "Gatekeeper add-on, so admission control is enforced in-cluster rather than only at plan time."
  type        = bool
  default     = true
}

variable "upgrade_channel" {
  description = "Automatic upgrade cadence. null pins the cluster and leaves upgrades manual."
  type        = string
  default     = "patch"

  validation {
    condition     = var.upgrade_channel == null || contains(["patch", "rapid", "stable", "node-image"], coalesce(var.upgrade_channel, "patch"))
    error_message = "upgrade_channel must be patch, rapid, stable, node-image, or null."
  }
}

variable "node_os_upgrade_channel" {
  description = "Cadence for node OS image patching."
  type        = string
  default     = "NodeImage"
}

variable "key_vault_secrets_provider_enabled" {
  description = "Mount Key Vault secrets as CSI volumes instead of copying them into Kubernetes Secrets."
  type        = bool
  default     = true
}

variable "secret_rotation_interval" {
  description = "How often the CSI driver re-reads rotated secrets."
  type        = string
  default     = "2m"
}

variable "node_pool_default" {
  description = "Values for the default azurerm_kubernetes_cluster.default_node_pool."
  type = object({
    name       = optional(string, "system")
    vm_size    = optional(string, "Standard_B2s")
    node_count = optional(number, 1)
    zones      = optional(list(string))

    auto_scaling_enabled = optional(bool, false)
    min_count            = optional(number)
    max_count            = optional(number)

    os_disk_size_gb = optional(number, 32)
    os_disk_type    = optional(string, "Managed")
    max_pods        = optional(number)

    # Taints the pool so only system addons schedule here. ForceNew - decide up front.
    only_critical_addons_enabled = optional(bool, false)

    vnet_subnet_id          = optional(string)
    host_encryption_enabled = optional(bool, false)
    max_surge               = optional(string, "10%")
  })
  default = {}

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,11}$", var.node_pool_default.name))
    error_message = "Pool name must be lowercase alphanumeric, start with a letter, and be at most 12 characters."
  }

  validation {
    condition     = !var.node_pool_default.auto_scaling_enabled || (var.node_pool_default.min_count != null && var.node_pool_default.max_count != null)
    error_message = "auto_scaling_enabled requires both min_count and max_count."
  }

  validation {
    condition     = var.node_pool_default.node_count >= 1
    error_message = "node_count must be at least 1; Azure has no zero-node system pool."
  }

  validation {
    condition     = contains(["Managed", "Ephemeral"], var.node_pool_default.os_disk_type)
    error_message = "os_disk_type must be Managed or Ephemeral."
  }
}

variable "additional_node_pools" {
  description = "Map with values for azurerm_kubernetes_cluster_node_pool"

  type = map(object({
    enabled = optional(bool, false)

    vm_size    = string
    node_count = optional(number, 1)
    mode       = optional(string, "User")
    os_type    = optional(string, "Linux")
    os_sku     = optional(string)
    zones      = optional(list(string))

    auto_scaling_enabled = optional(bool, false)
    min_count            = optional(number)
    max_count            = optional(number)

    os_disk_size_gb = optional(number, 32)
    os_disk_type    = optional(string, "Managed")
    max_pods        = optional(number)

    priority        = optional(string, "Regular")
    eviction_policy = optional(string)
    spot_max_price  = optional(number)

    node_labels = optional(map(string), {})
    node_taints = optional(list(string), [])

    vnet_subnet_id          = optional(string)
    host_encryption_enabled = optional(bool, false)
    fips_enabled            = optional(bool, false)
    orchestrator_version    = optional(string)
    max_surge               = optional(string, "10%")
  }))
  default = {}

  validation {
    condition     = alltrue([for p in var.additional_node_pools : contains(["User", "System"], p.mode) if p.enabled])
    error_message = "mode must be User or System."
  }

  validation {
    condition     = alltrue([for p in var.additional_node_pools : contains(["Regular", "Spot"], p.priority) if p.enabled])
    error_message = "priority must be Regular or Spot."
  }

  validation {
    # Azure requires Spot pools to be evictable and non-system.
    condition     = alltrue([for p in var.additional_node_pools : p.priority != "Spot" || (p.eviction_policy != null && p.mode == "User") if p.enabled])
    error_message = "Spot pools require eviction_policy (Delete or Deallocate) and mode User."
  }

  validation {
    condition     = alltrue([for p in var.additional_node_pools : !p.auto_scaling_enabled || (p.min_count != null && p.max_count != null) if p.enabled])
    error_message = "Pools with auto_scaling_enabled must set both min_count and max_count."
  }

  validation {
    condition     = alltrue([for k, p in var.additional_node_pools : can(regex("^[a-z][a-z0-9]{0,11}$", k))])
    error_message = "Pool names must be lowercase alphanumeric, start with a letter, and be at most 12 characters."
  }
}

variable "log_analytics_workspace_id" {
  description = "Workspace for container insights. null disables monitoring."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the cluster."
  type        = map(string)
  default     = {}
}
