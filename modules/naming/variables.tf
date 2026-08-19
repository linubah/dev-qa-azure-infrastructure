variable "brand" {
  description = "Organisation or brand short code. Kept to 4 chars so it survives the 24-char resource limits."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,5}$", var.brand))
    error_message = "brand must be 2-5 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment name, e.g. dev, qa, prod."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.environment))
    error_message = "environment must be 2-6 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region in slug form, e.g. westeurope."
  type        = string
}

variable "location_code" {
  description = "Short region code used inside names, e.g. euw1 for westeurope. Kept short because several Azure resources cap at 24 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.location_code))
    error_message = "location_code must be 2-6 lowercase alphanumeric characters."
  }
}

variable "workload" {
  description = "What this stack is for, e.g. core, data, web."
  type        = string
  default     = "core"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.workload))
    error_message = "workload must be 2-10 lowercase alphanumeric characters."
  }
}

variable "unique_suffix" {
  type    = bool
  default = true
}
