variable "subscription_id" {
  description = "Target Azure subscription."
  type        = string
}

variable "use_oidc" {
  description = "Authenticate via workload identity federation. Leave false for a local az login."
  type        = bool
  default     = false
}

# --- naming ---

variable "brand" {
  description = "Organisation short code, used as the first segment of every name."
  type        = string
  default     = "2ops"
}

variable "environment" {
  description = "Environment name. Must match the GitHub Environment this branch deploys to."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "location_code" {
  description = "Short region code used inside resource names."
  type        = string
  default     = "euw1"
}

variable "workload" {
  description = "What this stack is for."
  type        = string
  default     = "core"
}

variable "unique_suffix" {
  description = "Random suffix on globally unique names. Keep true while the environment is disposable."
  type        = bool
  default     = true
}

# --- storage account ---

variable "storage_replication_type" {
  description = "Redundancy for the storage account. LRS is the cheapest and enough for dev."
  type        = string
  default     = "LRS"
}

variable "storage_containers" {
  description = "Blob containers to create."
  type = map(object({
    access_type = optional(string, "private")
  }))
  default = {}
}

variable "allowed_ip_ranges" {
  description = "Public IPs allowed through resource firewalls. null leaves them open, which is what a demo needs."
  type        = list(string)
  default     = null
}

# --- aks (optional) ---

variable "aks_enabled" {
  description = <<-EOT
    Deploy the AKS cluster. Off by default: a free subscription's regional vCPU quota
    is usually 4, which one B2s node fits but little else does.
  EOT
  type        = bool
  default     = false
}

variable "aks_node_count" {
  description = "Nodes in the system pool."
  type        = number
  default     = 1
}

variable "aks_node_size" {
  description = "VM size for the system pool."
  type        = string
  default     = "Standard_B2s"
}

variable "aks_authorized_ip_ranges" {
  description = <<-EOT
    CIDRs allowed to reach the public API server. null leaves it open to the whole
    internet, which is why the default here is an empty-by-intent placeholder: set
    your own egress IP, or the GitHub runner ranges, before enabling AKS.

    Ignored when aks_private_cluster is true - a private cluster has no public
    endpoint left to restrict.
  EOT
  type        = list(string)
  default     = null

  validation {
    condition     = var.aks_authorized_ip_ranges == null || alltrue([for c in coalesce(var.aks_authorized_ip_ranges, []) : can(cidrnetmask(c))])
    error_message = "aks_authorized_ip_ranges must contain valid CIDR blocks, e.g. 203.0.113.4/32."
  }
}

variable "aks_private_cluster" {
  description = <<-EOT
    Give the API server a private endpoint and no public IP at all. Strongest option,
    but a GitHub-hosted runner cannot reach it - that needs a self-hosted runner in
    the VNet, a VPN, or a private endpoint. Left false so the demo pipeline works.
  EOT
  type        = bool
  default     = false
}

variable "aks_network_policy" {
  description = "Pod-to-pod traffic control. Without a policy engine every pod can reach every other pod."
  type        = string
  default     = "calico"
}

variable "aks_local_account_disabled" {
  description = <<-EOT
    Removes the static cluster-admin certificate that bypasses Entra ID, RBAC and MFA.
    Keep true: that credential never expires and appears in audit logs as "masterclient"
    rather than a person.
  EOT
  type        = bool
  default     = true
}

variable "aks_upgrade_channel" {
  description = "Automatic patch cadence, so the cluster does not sit on a version with known CVEs."
  type        = string
  default     = "patch"
}

variable "aks_admin_group_object_ids" {
  description = "Entra groups granted cluster-admin."
  type        = list(string)
  default     = []
}

variable "extra_tags" {
  description = "Tags merged on top of the ones the naming module produces."
  type        = map(string)
  default     = {}
}
