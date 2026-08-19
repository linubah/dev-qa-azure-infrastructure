#!/usr/bin/env bash

#
# Creates the Terraform state backend.
#

set -euo pipefail

BRAND="${BRAND:-2ops}"
LOCATION="${LOCATION:-westeurope}"
LOCATION_CODE="${LOCATION_CODE:-euw1}"
CONTAINER="${CONTAINER:-tfstate}"

RG_NAME="rg-${BRAND}-tfstate-${LOCATION_CODE}"

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
echo "Subscription: $(az account show --query name -o tsv) (${SUBSCRIPTION_ID})"

SUFFIX="$(printf '%s' "${SUBSCRIPTION_ID}" | shasum | cut -c1-6)"
SA_NAME="st${BRAND}tfstate${SUFFIX}"

echo "Resource group:  ${RG_NAME}"
echo "Storage account: ${SA_NAME}"
echo "Container:       ${CONTAINER}"
echo

az group create --name "${RG_NAME}" --location "${LOCATION}" --output none
echo "resource group ready"

if ! az storage account show --name "${SA_NAME}" --resource-group "${RG_NAME}" --output none 2>/dev/null; then
  az storage account create \
    --name "${SA_NAME}" \
    --resource-group "${RG_NAME}" \
    --location "${LOCATION}" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --https-only true \
    --allow-blob-public-access false \
    --allow-shared-key-access true \
    --output none
  echo "storage account created"
else
  echo "storage account already exists"
fi

az storage account blob-service-properties update \
  --account-name "${SA_NAME}" \
  --resource-group "${RG_NAME}" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 30 \
  --output none
echo "versioning and soft delete enabled"

az storage container create \
  --name "${CONTAINER}" \
  --account-name "${SA_NAME}" \
  --auth-mode login \
  --output none
echo "container ready"

USER_ID="$(az ad signed-in-user show --query id -o tsv)"
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Storage/storageAccounts/${SA_NAME}"

if ! az role assignment list --assignee "${USER_ID}" --scope "${SCOPE}" \
      --role "Storage Blob Data Contributor" --query "[0].id" -o tsv 2>/dev/null | grep -q .; then
  az role assignment create \
    --assignee "${USER_ID}" \
    --role "Storage Blob Data Contributor" \
    --scope "${SCOPE}" \
    --output none
  echo "granted Storage Blob Data Contributor (may take a few minutes to propagate)"
else
  echo "role assignment already present"
fi

cat <<SUMMARY

Backend ready. Write this into each environment's backend.hcl:

  resource_group_name  = "${RG_NAME}"
  storage_account_name = "${SA_NAME}"
  container_name       = "${CONTAINER}"
  key                  = "<env>.terraform.tfstate"
  use_azuread_auth     = true

SUMMARY
