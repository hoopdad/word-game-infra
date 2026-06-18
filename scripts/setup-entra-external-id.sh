#!/usr/bin/env bash
# setup-entra-external-id.sh — Configure Entra External ID for word-game
# Run as a local user with Application Administrator or Global Admin permissions.
# This script is idempotent.
set -euo pipefail

TENANT_ID="${TF_VAR_tenant_id:-$(az account show --query tenantId -o tsv)}"
PREFIX="wordgame-dev"

echo "=== Entra External ID Setup ==="
echo "Tenant: $TENANT_ID"
echo "Prefix: $PREFIX"
echo ""

# Step 1: Create API app registration
API_APP_NAME="${PREFIX}-api"
API_APP_ID=$(az ad app list --display-name "$API_APP_NAME" --query "[0].appId" -o tsv 2>/dev/null || true)
if [ -z "$API_APP_ID" ]; then
  echo "Creating API app registration: $API_APP_NAME"
  API_APP_ID=$(az ad app create \
    --display-name "$API_APP_NAME" \
    --sign-in-audience AzureADMyOrg \
    --query appId -o tsv)

  # Set identifier URI using the app's own ID (required by tenant policy)
  az ad app update --id "$API_APP_ID" \
    --identifier-uris "api://$API_APP_ID" --only-show-errors

  # Add access_as_user scope
  SCOPE_ID=$(cat /proc/sys/kernel/random/uuid)
  az ad app update --id "$API_APP_ID" --set api="{
    \"oauth2PermissionScopes\": [{
      \"id\": \"$SCOPE_ID\",
      \"value\": \"access_as_user\",
      \"type\": \"User\",
      \"isEnabled\": true,
      \"adminConsentDisplayName\": \"Access Word Game API\",
      \"adminConsentDescription\": \"Allows the app to call the Word Game API.\",
      \"userConsentDisplayName\": \"Access Word Game API\",
      \"userConsentDescription\": \"Allows this app to call the Word Game API on your behalf.\"
    }]
  }" --only-show-errors
else
  echo "API app registration already exists: $API_APP_ID"
fi

# Create SP for API app
az ad sp create --id "$API_APP_ID" --only-show-errors 2>/dev/null || true

# Step 2: Create Web (SPA) app registration
WEB_APP_NAME="${PREFIX}-web"
WEB_APP_ID=$(az ad app list --display-name "$WEB_APP_NAME" --query "[0].appId" -o tsv 2>/dev/null || true)
if [ -z "$WEB_APP_ID" ]; then
  echo "Creating Web app registration: $WEB_APP_NAME"
  WEB_APP_ID=$(az ad app create \
    --display-name "$WEB_APP_NAME" \
    --sign-in-audience AzureADandPersonalMicrosoftAccount \
    --enable-id-token-issuance false \
    --enable-access-token-issuance false \
    --web-redirect-uris "http://localhost:5173/auth/callback" \
    --query appId -o tsv)

  # Enable public client
  az ad app update --id "$WEB_APP_ID" --is-fallback-public-client true --only-show-errors
else
  echo "Web app registration already exists: $WEB_APP_ID"
fi

# Create SP for Web app
az ad sp create --id "$WEB_APP_ID" --only-show-errors 2>/dev/null || true

# Step 3: Configure self-service sign-up user flow (if supported)
echo ""
echo "Attempting to create self-service sign-up user flow..."
FLOW_NAME="B2C_1A_${PREFIX//-/_}_signup_signin"
az rest --method POST \
  --url "https://graph.microsoft.com/beta/identity/b2cUserFlows" \
  --headers "Content-Type=application/json" \
  --body "{
    \"id\": \"$FLOW_NAME\",
    \"userFlowType\": \"signUpOrSignIn\",
    \"userFlowTypeVersion\": 1,
    \"defaultLanguageTag\": \"en\",
    \"isLanguageCustomizationEnabled\": false
  }" 2>/dev/null || echo "(User flow may already exist or require B2C tenant)"

echo ""
echo "=== Entra External ID Setup Complete ==="
echo "API_CLIENT_ID=$API_APP_ID"
echo "WEB_CLIENT_ID=$WEB_APP_ID"
echo "TENANT_ID=$TENANT_ID"
echo ""
echo "Set these values for Terraform inputs before apply:"
echo "  TF_VAR_entra_api_client_id=$API_APP_ID"
echo "  TF_VAR_entra_web_client_id=$WEB_APP_ID"
