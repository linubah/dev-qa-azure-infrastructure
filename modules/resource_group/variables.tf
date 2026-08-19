variable "name" {
  description = "Resource group name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]{1,90}$", var.name)) && !endswith(var.name, ".")
    error_message = "Resource group name must be 1-90 chars of alphanumerics, '.', '_', '(', ')', '-' and cannot end with a period."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "tags" {
  description = "Tags applied to the resource group."
  type        = map(string)
  default     = {}
}
