# env/qa

QA environment. Resource group + key vault.

Modules come from `main` at `?ref=v1.0.0`. Promotion means bumping that ref.

## Deploy

```bash
cd environment
terraform init -backend-config=backend.hcl
terraform plan  -var-file=qa.tfvars -var="subscription_id=$(az account show --query id -o tsv)"
terraform apply -var-file=qa.tfvars -var="subscription_id=$(az account show --query id -o tsv)"
```

State lives in Azure, configured by `backend.hcl` — created by
`scripts/bootstrap-backend.sh` on `main`.

## Key Vault

- **RBAC, not access policies.** Grant access through `key_vault_role_assignments`
  rather than by hand; the vault and its grants then live in one state and one review.
- **Purge protection is off.** It cannot be turned back off once enabled, and it holds
  the vault name for the whole soft-delete window after a destroy. Production wants it on.
- Names get a random suffix for the same reason — a fixed name blocks recreating a
  destroyed environment for days.
- The provider sets `purge_soft_delete_on_destroy`, so `terraform destroy` frees the
  name immediately instead of leaving a soft-deleted vault behind.
