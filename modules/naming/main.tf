resource "random_string" "suffix" {
  count = var.unique_suffix ? 1 : 0

  length  = 4
  special = false
  upper   = false
  numeric = false
}

locals {
  suffix      = var.unique_suffix ? random_string.suffix[0].result : ""
  suffix_part = var.unique_suffix ? "-${local.suffix}" : ""

  base         = join("-", [var.brand, var.environment, var.location_code, var.workload])
  base_compact = join("", [var.brand, var.environment, var.location_code, var.workload])

  names = {
    resource_group = "rg-${local.base}"
    aks            = "aks-${local.base}"

    # Trim the base, never the suffix - cutting the whole string eats the random
    # part and can leave a trailing hyphen, which Azure rejects.
    storage_account = "st${substr(local.base_compact, 0, 24 - 2 - length(local.suffix))}${local.suffix}"

    key_vault = "kv-${trimsuffix(substr(local.base, 0, 24 - 3 - length(local.suffix_part)), "-")}${local.suffix_part}"
  }

  tags = {
    brand       = var.brand
    environment = var.environment
    location    = var.location
    workload    = var.workload
    managed_by  = "terraform"
  }
}
