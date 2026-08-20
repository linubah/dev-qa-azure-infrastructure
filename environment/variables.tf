# --- naming ---

variable "brand" {
  description = "Organisation short code."
  type        = string
  default     = "2ops"
}

variable "environment" {
  description = "Environment name. Must match the GitHub Environment."
  type        = string
  default     = "qa"
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
  description = "Random suffix on globally unique names. A deleted vault holds its name for the retention window."
  type        = bool
  default     = true
}

# --- key vault ---

variable "key_vault_sku" {
  description = "standard, or premium for HSM-backed keys."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "key_vault_sku must be standard or premium."
  }
}

variable "key_vault_purge_protection" {
  description = "Irreversible once on, and holds the vault name after a destroy. Production wants true."
  type        = bool
  default     = false
}

variable "key_vault_soft_delete_retention_days" {
  description = "Days a deleted vault stays recoverable. 7 is Azure's minimum."
  type        = number
  default     = 7
}

variable "key_vault_rbac_authorization" {
  description = "Azure RBAC instead of legacy access policies."
  type        = bool
  default     = true
}

variable "key_vault_role_assignments" {
  description = "Entra principals granted a built-in Key Vault role."
  type = map(object({
    role         = string
    principal_id = string
  }))
  default = {}
}

variable "allowed_ip_ranges" {
  description = "Public IPs allowed through the vault firewall. null leaves it open."
  type        = list(string)
  default     = null

  validation {
    condition     = var.allowed_ip_ranges == null || alltrue([for c in coalesce(var.allowed_ip_ranges, []) : can(cidrnetmask(c)) || can(regex("^\\d{1,3}(\\.\\d{1,3}){3}$", c))])
    error_message = "allowed_ip_ranges must contain valid public IPv4 addresses or CIDR blocks."
  }
}

variable "extra_tags" {
  description = "Tags merged on top of the naming module's."
  type        = map(string)
  default     = {}
}
