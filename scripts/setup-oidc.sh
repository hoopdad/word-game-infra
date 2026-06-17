#!/usr/bin/env bash
# setup-oidc.sh — Configure OIDC federation for GitHub Actions deployment
# Run as a local user with Owner/App Admin permissions on the subscription.
# This script is idempotent.
set -euo pipefail

SUBSCRIPTION_ID="${TF_VAR_subscription_id:-$(az account show --query id -o tsv)}"
TENANT_ID="${TF_VAR_tenant_id:-$(az account show --query tenantId -o tsv)}"
GITHUB_REPO="${TF_VAR_github_repository:-hoopdad/word-game}"
GITHUB_BRANCH="${TF_VAR_github_branch:-main}"
APP_NAME="wordgame-dev-gha"
RG_NAME="wordgame-dev-rg"

echo "=== OIDC Setup for GitHub Actions ==="
echo "Subscription: $SUBSCRIPTION_ID"
echo "Tenant:       $TENANT_ID"
echo "GitHub Repo:  $GITHUB_REPO"
echo "App Name:     $APP_NAME"
echo ""

# Step 1: Create app registration (if not exists)
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv 2>/dev/null || true)
if [ -z "$APP_ID" ]; then
  echo "Creating app registration: $APP_NAME"
  APP_ID=$(az ad app create --display-name "$APP_NAME" --sign-in-audience AzureADMyOrg --query appId -o tsv)
else
  echo "App registration already exists: $APP_ID"
fi

# Step 2: Create service principal (if not exists)
SP_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv 2>/dev/null || true)
if [ -z "$SP_ID" ]; then
  echo "Creating service principal..."
  SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
else
  echo "Service principal already exists: $SP_ID"
fi

# Step 3: Add federated credential for main branch
CRED_NAME="github-actions-main"
EXISTING_CRED=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$CRED_NAME'].name" -o tsv 2>/dev/null || true)
if [ -z "$EXISTING_CRED" ]; then
  echo "Adding federated identity credential for branch: $GITHUB_BRANCH"
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"$CRED_NAME\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_REPO:ref:refs/heads/$GITHUB_BRANCH\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" --only-show-errors >/dev/null
else
  echo "Federated credential already exists: $CRED_NAME"
fi

# Step 4: Assign Contributor role on resource group
echo "Assigning Contributor role on $RG_NAME..."
az role assignment create \
  --assignee "$SP_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME" \
  --only-show-errors 2>/dev/null || echo "(Role assignment may already exist)"

echo ""
echo "=== OIDC Setup Complete ==="
echo "CLIENT_ID=$APP_ID"
echo "TENANT_ID=$TENANT_ID"
echo "SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
echo ""
echo "Add these as GitHub Actions secrets:"
echo "  AZURE_CLIENT_ID=$APP_ID"
echo "  AZURE_TENANT_ID=$TENANT_ID"
echo "  AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
