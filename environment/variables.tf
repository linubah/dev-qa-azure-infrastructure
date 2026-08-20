# --- naming ---

variable "brand" {
  description = "Organisation short code."
  type        = string
  default     = "2ops"
}

variable "environment" {
  description = "Environment name. Must match the GitHub Environment."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "location_code" {
  description = "Short region code used in resource names."
  type        = string
  default     = "euw1"
}

variable "workload" {
  description = "What this stack is for."
  type        = string
  default     = "core"
}

variable "unique_suffix" {
  description = "Random suffix on globally unique names, so a destroyed env can be recreated at once."
  type        = bool
  default     = true
}

# --- storage account ---

variable "storage_replication_type" {
  description = "Redundancy. LRS is cheapest and enough for dev."
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
  description = "Public IPs allowed through resource firewalls. null leaves them open."
  type        = list(string)
  default     = null
}

# --- aks (optional) ---

variable "aks_enabled" {
  description = "Deploy the AKS cluster. Off by default - a free subscription's 4 vCPU quota fits one node."
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
  description = "CIDRs allowed to reach the API server. null leaves it open to the internet."
  type        = list(string)
  default     = null

  validation {
    condition     = var.aks_authorized_ip_ranges == null || alltrue([for c in coalesce(var.aks_authorized_ip_ranges, []) : can(cidrnetmask(c))])
    error_message = "aks_authorized_ip_ranges must contain valid CIDR blocks, e.g. 203.0.113.4/32."
  }
}

variable "aks_private_cluster" {
  description = "Private API server endpoint. GitHub-hosted runners cannot reach one."
  type        = bool
  default     = false
}

variable "aks_network_policy" {
  description = "Pod-to-pod traffic control. Without it every pod reaches every pod."
  type        = string
  default     = "calico"
}

variable "aks_local_account_disabled" {
  description = "Removes the static cluster-admin certificate that bypasses Entra ID and MFA."
  type        = bool
  default     = true
}

variable "aks_upgrade_channel" {
  description = "Automatic patch cadence, so the cluster does not sit on known CVEs."
  type        = string
  default     = "patch"
}

variable "aks_admin_group_object_ids" {
  description = "Entra groups granted cluster-admin."
  type        = list(string)
  default     = []
}

variable "extra_tags" {
  description = "Tags merged on top of the naming module's."
  type        = map(string)
  default     = {}
}
