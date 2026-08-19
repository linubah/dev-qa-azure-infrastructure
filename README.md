# env/dev

DEV environment. Resource group + storage account, with AKS behind a flag.

Modules come from `main` at `?ref=v1.x.0`. Promotion means bumping that ref.

## Deploy

```bash
cd environment
terraform init -backend-config=backend.hcl
terraform plan  -var-file=dev.tfvars -var="subscription_id=$(az account show --query id -o tsv)"
terraform apply -var-file=dev.tfvars -var="subscription_id=$(az account show --query id -o tsv)"
```

State lives in Azure, configured by `backend.hcl` — created by
`scripts/bootstrap-backend.sh` on `main`.