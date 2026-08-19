variable "name" {
  description = "Storage account name. Globally unique, no hyphens allowed."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
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

variable "account_tier" {
  description = "Performance tier."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "replication_type" {
  description = "Redundancy option."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be one of LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "account_kind" {
  description = "Storage account kind."
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Blob access tier for StorageV2 accounts."
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}

variable "shared_access_key_enabled" {
  description = "Allow access-key auth. Disabled by default so Entra ID is the only path."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Expose the account on its public endpoint. false requires private endpoints to reach it."
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "Public IPs/CIDRs allowed through the firewall. null skips network rules entirely."
  type        = list(string)
  default     = null

  validation {
    condition     = var.allowed_ip_ranges == null || alltrue([for c in coalesce(var.allowed_ip_ranges, []) : can(cidrnetmask(c)) || can(regex("^\\d{1,3}(\\.\\d{1,3}){3}$", c))])
    error_message = "allowed_ip_ranges must contain valid public IPv4 addresses or CIDR blocks. Azure rejects private ranges."
  }
}

variable "network_rules_default_action" {
  description = "Firewall posture when allowed_ip_ranges is set."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_rules_default_action)
    error_message = "network_rules_default_action must be Allow or Deny."
  }
}

variable "network_rules_bypass" {
  description = "Traffic permitted to skip the firewall."
  type        = list(string)
  default     = ["AzureServices"]

  validation {
    condition     = alltrue([for b in var.network_rules_bypass : contains(["AzureServices", "Logging", "Metrics", "None"], b)])
    error_message = "network_rules_bypass entries must be AzureServices, Logging, Metrics, or None."
  }
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs granted access via service endpoints."
  type        = list(string)
  default     = []
}

variable "versioning_enabled" {
  description = "Keep previous blob versions, so an overwrite is recoverable and not just a delete. Versions bill as separate blobs and are never pruned without a lifecycle policy."
  type        = bool
  default     = true
}

variable "blob_retention_days" {
  description = "Soft-delete retention for blobs. 0 disables."
  type        = number
  default     = 7

  validation {
    condition     = var.blob_retention_days >= 0 && var.blob_retention_days <= 365
    error_message = "blob_retention_days must be between 0 and 365."
  }
}

variable "containers" {
  description = "Blob containers to create."
  type = map(object({
    access_type = optional(string, "private")
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the storage account."
  type        = map(string)
  default     = {}
}
