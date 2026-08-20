# env/qa

QA environment. Resource group + key vault.

Modules come from `main` at `?ref=v1.xx.0`. Promotion means bumping that ref.

## Deploy

```bash
cd environment
terraform init -backend-config=backend.hcl
terraform plan  -var-file=qa.tfvars
terraform apply -var-file=qa.tfvars
```

State lives in Azure, configured by `backend.hcl` — created by
`scripts/bootstrap-backend.sh` on `main`.
