# naming

Builds resource names and common tags from one convention, so every module in a stack
agrees on what things are called.

## Convention

```
{brand}-{environment}-{location_code}-{workload}[-{suffix}]
  2ops  -    dev     -     euw1       -  core   -  vcem
```

Prefix per resource type follows the Azure CAF abbreviations: `rg-`, `st`, `kv-`, `aks-`.

| Resource | Example | Limit |
|---|---|---|
| resource group | `rg-2ops-dev-euw1-core` | 90 |
| storage account | `st2opsdeveuw1corevcem` | 24, no hyphens, lowercase |
| key vault | `kv-2ops-dev-euw1-co-vcem` | 24 |
| aks | `aks-2ops-dev-euw1-core` | 63 |
| vnet | `vnet-2ops-dev-euw1-core` | 64 |

## Truncation

Storage accounts and key vaults cap at 24 characters, which a four-part name plus a suffix
can exceed. The module trims **the base, never the suffix** - cutting the finished string
would eat the random part that makes the name unique, and can leave a trailing hyphen that
Azure rejects outright.

## unique_suffix

Defaults to `true`. Storage accounts and key vaults are globally unique across Azure, and a
deleted Key Vault holds its name for the entire soft-delete window (7-90 days). Without a
random suffix, tearing down a disposable environment blocks re-creating it.

Set it to `false` for long-lived environments that want predictable names.

## Usage

```hcl
module "naming" {
  source = "../../modules/naming"

  brand         = "2ops"
  environment   = "dev"
  location      = "westeurope"
  location_code = "euw1"
}

module "resource_group" {
  source   = "../../modules/resource_group"
  name     = module.naming.resource_group
  location = var.location
  tags     = module.naming.tags
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `brand` | `string` | — | Organisation short code, 2-5 lowercase alphanumerics. |
| `environment` | `string` | — | `dev`, `qa`, `prod`. |
| `location` | `string` | — | Azure region slug, used in tags. |
| `location_code` | `string` | — | Short region code for names, e.g. `euw1`. |
| `workload` | `string` | `"core"` | What the stack is for. |
| `unique_suffix` | `bool` | `true` | Random 4-char suffix on globally unique names. |

## Outputs

| Name | Description |
|---|---|
| `resource_group` | Resource group name. |
| `storage_account` | Storage account name. |
| `key_vault` | Key Vault name. |
| `aks` | AKS cluster name. |
| `vnet` | Virtual network name. |
| `tags` | Common tags to merge into every resource. |
