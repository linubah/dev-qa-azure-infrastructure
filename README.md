# Azure infrastructure — DEV / QA

Terraform modules on `main`, one branch per environment, deployed by a shared GitHub
Actions pipeline authenticating with OIDC.

## Layout

```
main          modules/ + reusable workflow + bootstrap script, tagged v1.xxx.0
env/dev       resource group + storage account, AKS behind a flag
env/qa        resource group + key vault
```

Each environment branch holds only a root module, consuming `main` by immutable tag:

```hcl
source = "git::https://github.com/…//modules/storage_account?ref=v1.xxx.0"
```

Upgrading an environment is a one-line ref bump, visible in the diff. The pipeline lives
on `main` as a reusable workflow that each branch calls, so both environments share one copy.

## Modules

Each resource is its own module: `resource_group`, `storage_account`, `key_vault`,
`network`, `aks`, plus `naming`.

`naming` produces every resource name and the shared tag set from one convention:

```
{brand}-{env}-{location_code}-{workload}[-{suffix}]
  2ops  - dev -     euw1     -  core    -  vcem
```

Globally unique names get a random suffix, because a deleted key vault holds its name
for the soft-delete window and would block recreating the environment.

Modules hardcode TLS 1.2, HTTPS-only and no anonymous blob access; anything that varies
per environment is a variable.

## Pipeline

```
push / PR ─> plan ──────────> apply
             Reader           Contributor, applies the saved plan artifact
             ungated          required reviewers
```

Plan runs as a Reader identity and is not bound to a GitHub Environment, so it reports
without waiting for approval. Apply is environment-bound, holds Contributor, and pauses
for a reviewer.

Apply consumes the plan artifact rather than re-planning, so anything merged in between
fails as a stale plan.

The workflow also runs `fmt` and `validate`, posts the plan as a PR comment, holds a
per-environment concurrency lock, and triggers only on changes under `environment/` or
`.github/workflows/`.

## Credentials and authorisation

Four Entra app registrations use workload identity federation — an apply and a plan
identity per environment. No long-lived secrets exist; the runner exchanges a signed
GitHub token for an Azure one. Roles are scoped to a single resource group each.

Client, tenant and subscription ids are GitHub **variables**: apply reads them from the
environment scope, plan from the repository scope.

Deployments are gated by required reviewers on both environments, a deployment branch
policy tying each environment to its own branch, and an OIDC subject pinned to this
repository's id.

## State

Azure Storage, one state file per environment in a shared container, created by
`scripts/bootstrap-backend.sh`. Versioning and soft delete are enabled; access is via
Entra ID with account keys disabled.

State is never committed — it holds API values in plain text. A pre-commit hook blocks
`.tfstate` and plan files.

## Setup

One-time, by a human with Owner rights, since it grants permissions the pipeline never
holds:

1. `scripts/bootstrap-backend.sh` — creates the state storage account
2. `terraform apply -target=module.resource_group` from each environment branch
3. Create the app registrations, their federated credentials, and the role assignments
4. Create the GitHub environments, set the variables, add reviewers and branch policies

Step 2 comes first because the roles in step 3 are scoped to those resource groups. That
scoping means the pipeline cannot create a resource group.

## Deploying

Push to an environment branch and approve the apply, or run locally:

```bash
cd environment
terraform init -backend-config=backend.hcl
terraform plan -var-file=dev.tfvars
```
