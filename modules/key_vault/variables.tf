variable "name" {
  description = "Key Vault name. Globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "Key Vault name must be 3-24 alphanumeric characters or hyphens."
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

variable "tenant_id" {
  description = "Entra tenant the vault trusts. null inherits the tenant of the credentials Terraform runs under."
  type        = string
  default     = null
}

variable "sku" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku)
    error_message = "sku must be standard or premium."
  }
}

variable "rbac_authorization_enabled" {
  description = "Use Azure RBAC instead of legacy access policies."
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Irreversible once enabled - blocks reusing the vault name for the retention window."
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Days a soft-deleted vault is recoverable."
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "enabled_for_deployment" {
  description = "Allow VMs to retrieve certificates from the vault."
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption to retrieve secrets."
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow ARM/Bicep deployments to retrieve secrets."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Expose the vault on its public endpoint."
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "Public IPs/CIDRs allowed through the firewall. null skips network ACLs entirely."
  type        = list(string)
  default     = null

  validation {
    condition     = var.allowed_ip_ranges == null || alltrue([for c in coalesce(var.allowed_ip_ranges, []) : can(cidrnetmask(c)) || can(regex("^\\d{1,3}(\\.\\d{1,3}){3}$", c))])
    error_message = "allowed_ip_ranges must contain valid public IPv4 addresses or CIDR blocks. Azure rejects private ranges."
  }
}

variable "network_acls_default_action" {
  description = "Firewall posture when an allow-list is supplied."
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "network_acls_default_action must be Allow or Deny."
  }
}

variable "network_acls_bypass" {
  description = "Whether trusted Azure services skip the firewall. Key Vault accepts a single value, not a list."
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "network_acls_bypass must be AzureServices or None."
  }
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs granted access via service endpoints."
  type        = list(string)
  default     = []
}

variable "role_assignments" {
  description = "Entra principals granted a built-in Key Vault role. Only effective with RBAC authorization."
  type = map(object({
    role         = string
    principal_id = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the Key Vault."
  type        = map(string)
  default     = {}
}
