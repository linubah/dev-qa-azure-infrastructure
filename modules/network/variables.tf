variable "name" {
  description = "Virtual network name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "VNet address space. Must not overlap the AKS service_cidr."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.address_space : can(cidrnetmask(c))])
    error_message = "address_space must contain valid CIDR blocks."
  }
}

variable "subnets" {
  description = "Subnets keyed by name. service_endpoints keep traffic to Storage or Key Vault on the Azure backbone."
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name    = string
      actions = list(string)
    }))
  }))

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrnetmask(s.address_prefix))])
    error_message = "Each subnet address_prefix must be a valid CIDR block."
  }
}

variable "nsg_rules" {
  description = "Extra inbound rules per subnet. Every subnet gets an NSG regardless; priorities must be below 4000 to sit above the deny-vnet rule."
  type = map(list(object({
    name                       = string
    priority                   = number
    direction                  = optional(string, "Inbound")
    access                     = optional(string, "Allow")
    protocol                   = optional(string, "Tcp")
    source_port_range          = optional(string, "*")
    destination_port_range     = string
    source_address_prefix      = optional(string)
    destination_address_prefix = optional(string, "*")
  })))
  default = {}

  validation {
    condition     = alltrue(flatten([for rules in var.nsg_rules : [for r in rules : r.priority > 100 && r.priority < 4000]]))
    error_message = "Rule priorities must be between 101 and 3999."
  }
}

variable "flow_log_storage_account_id" {
  description = "Storage account for NSG flow logs. null disables them."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
