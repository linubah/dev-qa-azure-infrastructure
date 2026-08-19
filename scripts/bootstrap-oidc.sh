#!/usr/bin/env bash
# Creates one Entra app per environment and wires it to GitHub Actions via OIDC.
#
# Run after the resource groups exist - roles are scoped to them, so they must be
# there to be scoped to.

set -euo pipefail

REPO="${REPO:-linubah/dev-qa-azure-infrastructure}"
BRAND="${BRAND:-2ops}"
LOCATION_CODE="${LOCATION_CODE:-euw1}"
WORKLOAD="${WORKLOAD:-core}"
ENVIRONMENTS="${ENVIRONMENTS:-dev qa}"

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
STATE_RG="rg-${BRAND}-tfstate-${LOCATION_CODE}"
STATE_SA="st${BRAND}tfstate$(printf '%s' "${SUBSCRIPTION_ID}" | shasum | cut -c1-6)"

echo "Repository:   ${REPO}"
echo "Subscription: ${SUBSCRIPTION_ID}"
echo "Tenant:       ${TENANT_ID}"
echo

for ENV in ${ENVIRONMENTS}; do
  APP_NAME="gha-${BRAND}-${ENV}"
  ENV_RG="rg-${BRAND}-${ENV}-${LOCATION_CODE}-${WORKLOAD}"

  echo "--- ${ENV} ---"

  if ! az group show --name "${ENV_RG}" --output none 2>/dev/null; then
    echo "  resource group ${ENV_RG} does not exist yet - run step 3 first" >&2
    exit 1
  fi

  APP_ID="$(az ad app list --display-name "${APP_NAME}" --query "[0].appId" -o tsv)"
  if [[ -z "${APP_ID}" ]]; then
    APP_ID="$(az ad app create --display-name "${APP_NAME}" --query appId -o tsv)"
    echo "  created app ${APP_NAME}"
  else
    echo "  app ${APP_NAME} already exists"
  fi

  # The service principal is what role assignments actually bind to.
  if ! az ad sp show --id "${APP_ID}" --output none 2>/dev/null; then
    az ad sp create --id "${APP_ID}" --output none
    echo "  created service principal"
  fi
  SP_ID="$(az ad sp show --id "${APP_ID}" --query id -o tsv)"

  # GitHub signs the subject claim itself, so this cannot be forged by a workflow.
  # Binding to :environment: also means fork PRs get nothing - GitHub does not
  # activate environments for them.
  SUBJECT="repo:${REPO}:environment:${ENV}"
  if ! az ad app federated-credential list --id "${APP_ID}" \
        --query "[?subject=='${SUBJECT}'].name" -o tsv 2>/dev/null | grep -q .; then
    az ad app federated-credential create --id "${APP_ID}" --parameters "{
      \"name\": \"gha-env-${ENV}\",
      \"issuer\": \"https://token.actions.githubusercontent.com\",
      \"subject\": \"${SUBJECT}\",
      \"audiences\": [\"api://AzureADTokenExchange\"]
    }" --output none
    echo "  federated credential -> ${SUBJECT}"
  else
    echo "  federated credential already present"
  fi

  # Contributor on this environment's group only.
  ENV_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${ENV_RG}"
  if ! az role assignment list --assignee "${SP_ID}" --scope "${ENV_SCOPE}" \
        --role Contributor --query "[0].id" -o tsv 2>/dev/null | grep -q .; then
    az role assignment create --assignee-object-id "${SP_ID}" --assignee-principal-type ServicePrincipal \
      --role Contributor --scope "${ENV_SCOPE}" --output none
    echo "  Contributor on ${ENV_RG}"
  else
    echo "  Contributor already granted"
  fi

  # Terraform reads and writes state blobs, which Contributor on the account does
  # not allow - that is management plane, this is data plane.
  STATE_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${STATE_RG}/providers/Microsoft.Storage/storageAccounts/${STATE_SA}"
  if ! az role assignment list --assignee "${SP_ID}" --scope "${STATE_SCOPE}" \
        --role "Storage Blob Data Contributor" --query "[0].id" -o tsv 2>/dev/null | grep -q .; then
    az role assignment create --assignee-object-id "${SP_ID}" --assignee-principal-type ServicePrincipal \
      --role "Storage Blob Data Contributor" --scope "${STATE_SCOPE}" --output none
    echo "  Storage Blob Data Contributor on ${STATE_SA}"
  else
    echo "  state access already granted"
  fi

  # Key Vault RBAC is separate again: Contributor can delete a vault but not read it.
  if [[ "${ENV}" == "qa" ]]; then
    if ! az role assignment list --assignee "${SP_ID}" --scope "${ENV_SCOPE}" \
          --role "Key Vault Administrator" --query "[0].id" -o tsv 2>/dev/null | grep -q .; then
      az role assignment create --assignee-object-id "${SP_ID}" --assignee-principal-type ServicePrincipal \
        --role "Key Vault Administrator" --scope "${ENV_SCOPE}" --output none
      echo "  Key Vault Administrator on ${ENV_RG}"
    fi
  fi

  echo "  AZURE_CLIENT_ID=${APP_ID}"
  echo
done

cat <<SUMMARY
Set these as GitHub Actions *variables* (not secrets - none of them are secret)
in each environment at Settings > Environments:

  AZURE_TENANT_ID       ${TENANT_ID}
  AZURE_SUBSCRIPTION_ID ${SUBSCRIPTION_ID}
  AZURE_CLIENT_ID       per environment, printed above

gh CLI equivalent:

  gh variable set AZURE_TENANT_ID       --env dev --body "${TENANT_ID}"
  gh variable set AZURE_SUBSCRIPTION_ID --env dev --body "${SUBSCRIPTION_ID}"
  gh variable set AZURE_CLIENT_ID       --env dev --body "<dev app id>"
SUMMARY
