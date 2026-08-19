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

# --- default node pool ---

variable "node_count" {
  description = "Node count when autoscaling is off, or the initial count when on."
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "node_count must be between 1 and 100."
  }
}

variable "node_size" {
  description = "VM size for the default node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "node_os_disk_size_gb" {
  description = "OS disk size per node."
  type        = number
  default     = 32
}

variable "auto_scaling_enabled" {
  description = "Enable cluster autoscaler on the default pool."
  type        = bool
  default     = false
}

variable "min_node_count" {
  description = "Autoscaler floor. Required when auto_scaling_enabled."
  type        = number
  default     = null
}

variable "max_node_count" {
  description = "Autoscaler ceiling. Required when auto_scaling_enabled."
  type        = number
  default     = null
}

variable "vnet_subnet_id" {
  description = "Subnet for node NICs. null lets AKS manage its own VNet."
  type        = string
  default     = null
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

variable "only_critical_addons_enabled" {
  description = "Taint the system pool so it carries only control-plane addons. Needs a second user pool for workloads."
  type        = bool
  default     = false
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

variable "max_pods_per_node" {
  description = "Pod density per node. null takes the plugin default (30 for Azure CNI)."
  type        = number
  default     = null
}

variable "host_encryption_enabled" {
  description = "Encrypt temp disks and caches at the host. Requires the EncryptionAtHost feature on the subscription."
  type        = bool
  default     = false
}

variable "os_disk_type" {
  description = "Ephemeral is faster and free but is lost on reimage and needs a VM SKU with a big enough cache."
  type        = string
  default     = "Managed"

  validation {
    condition     = contains(["Managed", "Ephemeral"], var.os_disk_type)
    error_message = "os_disk_type must be Managed or Ephemeral."
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
