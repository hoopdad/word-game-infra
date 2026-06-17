# Work Request: Infrastructure — Full Azure Deployment

## References
- Requirements: `.requirements/infrastructure.yml`, `.requirements/auth.yml`, `.requirements/platform-guardrails.yml`
- Guardrails: `.copilot/guardrails/pattern.yml`, `.copilot/guardrails/nfr.yml`

## Context
This is a **greenfield repo**. Scaffold the complete Terraform configuration from scratch.
All infrastructure for the word-game multiplayer platform must be provisioned in Azure Central US.

## Acceptance Criteria

### 1. Networking (Use spoke-skill / mcaps-spoke-skill)
- VNet with spoke topology using the spoke-skill to scaffold Terraform
- **Do NOT add private DNS zones to the spoke — only to the hub**
- Reference Hub with data blocks, and a separate provider for the Hub and Spoke subscriptions. ID'd in .env
- Subnets: ingress (WAF), container-apps (delegated for Microsoft.App/environments), private-endpoints
- NSGs on every subnet with deny-all-inbound default, allow only required flows
- Container Apps Environment in internal mode (VNet-integrated)
- Track every network flow in .contracts: inbound --> waf --> web/api [optional --> agent/database ] including source and target service and port 

### 2. Container Apps
- Three Container Apps: `word-game-web`, `word-game-api`, `word-game-agent`
- Plus one for WAF: `word-game-waf` (no public ingress on the ingress subnet)
- Consumption plan, min replicas: 1
- Right-size: 0.25 vCPU / 0.5 Gi memory starting point
- API container app must have internal ingress only (not external)
- Agent container app must have internal ingress only — NOT exposed publicly
- Web container app internal ingress (behind WAF)
- WAF container app: internal ingress
- Health probes (liveness + readiness) on all Container Apps
- User-assigned managed identity with AcrPull role
- Design to handle issues with old revisions sticking around

### 3. Cosmos DB
- NoSQL API, serverless capacity mode, session consistency
- Database: `word-game`
- Containers with access-pattern-driven partition keys:
  - `users` — partition key: `/id` — stores user profiles
  - `games` — partition key: `/id` — stores game state (use singleton control doc `active-game` for single-game lock)
  - `scores` — partition key: `/userId` — per-user scoring for leaderboard queries
  - `category_config` — partition key: `/id` — category URL configuration
- Private endpoint on private-endpoints subnet
- Track all schema in .contracts ; create if not existing

### 4. Azure Container Registry
- Premium SKU, so we can use private endpoints
- User-assigned managed identity with AcrPull role on Container Apps
- Private endpoint on private-endpoints subnet

### 5. Key Vault
- Standard SKU, RBAC access (Key Vault Secrets User for managed identity and current user)
- Store: Cosmos connection string, Foundry endpoint/key, Entra client IDs
- Private endpoint on private-endpoints subnet

### 6. Azure AI Foundry
- AI Foundry project (hub + project)
- GPT-4.1-mini model deployment (or equivalent)
- Managed identity access for agent Container App
- If no AVM exists for AI Foundry, use native azurerm resources and log the exception

### 7. Monitoring
- Use centralized Log Analytics workspace in hub with daily cap (e.g., 1 GB/day for dev)
- Application Insights connected to Log Analytics
- All Diagnostic settings on Container Apps, Cosmos DB

### 8. Identity
- User-assigned managed identity for Container Apps
- RBAC roles: AcrPull (ACR), Cosmos DB Data Contributor (Cosmos), Key Vault Secrets User (Key Vault), Cognitive Services User (Foundry)
- OIDC federation for GitHub Actions (for CI/CD deployment)
- Write and run a script to do all OIDC and Azure App Registration and run it as local user, not in GH Action

### 9. Entra External ID (via AZ CLI in scripts or null_resource)
- App registration for web (SPA, public client, redirect URIs)
- App registration for API (exposed scope: `access_as_user`)
- Self-service sign-up user flow
- Output client IDs and tenant info as Terraform outputs for consumption by other repos
- Write and run a script to configure Azure to allow this

### 10. Terraform Standards
- Use Azure Verified Modules (AVM) wherever available
- azurerm provider >= 4.0
- Naming: `wordgame-{env}-{resource}` (e.g., `wordgame-dev-cosmos`)
- Common tags: project=word-game, environment=dev, managed_by=terraform
- Outputs for: Container App FQDNs, Cosmos endpoint, ACR login server, Key Vault URI, Entra client IDs, managed identity client ID

## Platform Constraints
- All resources in Central US region
- Private networking with no public endpoints except WAF ingress
- Managed identities for all service-to-service auth
- No secrets in code or Terraform state exposed publicly
- Use spoke-skill for networking scaffold — do NOT place private DNS zones in spoke

## Validation
- `terraform fmt -check -recursive`
- `terraform validate` (after `terraform init`)
- All files must pass validation before handoff


## Implementation Summary (Specialist)

**Changes made:**
1. **Networking**: Edge CAE set to `internal_load_balancer_enabled = true`; WAF ingress set to internal-only. Hub data blocks added with separate `azurerm.hub` provider alias. NSG allow rule added on PE subnet for container-apps traffic (ports 443, 10255, 1433).
2. **Container Apps**: All 4 apps set to `min_replicas = 1`. WAF `external_enabled = false`. Revision mode stays `Single` (auto-deactivates old revisions).
3. **ACR**: Always Premium SKU with private endpoint (removed conditional toggle). Removed `enable_acr_private_endpoint` variable.
4. **Identity**: Added `data.azurerm_client_config.current` and Key Vault Secrets User role for deploying user.
5. **Monitoring**: Added `data.azurerm_log_analytics_workspace.hub` for optional hub LAW reference.
6. **Contracts**: Created `.contracts/network-flows.yml` and `.contracts/cosmos-schema.yml`.
7. **Scripts**: Created `scripts/setup-oidc.sh` and `scripts/setup-entra-external-id.sh` (idempotent, run as local user).
8. **Gitignore**: Added `.env` and `tfplan` to prevent secrets/binary in repo.

**Validation:**
- `terraform fmt -check -recursive` ✅
- `terraform validate` ✅
- `terraform plan` — requires real Azure credentials (placeholder GUIDs in defaults)
