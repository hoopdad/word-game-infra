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
- Subnets: ingress (WAF), container-apps (delegated for Microsoft.App/environments), private-endpoints
- NSGs on every subnet with deny-all-inbound default, allow only required flows
- Container Apps Environment in internal mode (VNet-integrated)

### 2. Container Apps
- Three Container Apps: `word-game-web`, `word-game-api`, `word-game-agent`
- Plus one for WAF: `word-game-waf` (external ingress on the ingress subnet)
- Consumption plan, scale-to-zero for non-prod (min replicas: 0)
- Right-size: 0.25 vCPU / 0.5 Gi memory starting point
- API container app must have internal ingress only (not external)
- Agent container app must have internal ingress only — NOT exposed publicly
- Web container app internal ingress (behind WAF)
- WAF container app: external ingress (the only public-facing service)
- Health probes (liveness + readiness) on all Container Apps
- User-assigned managed identity with AcrPull role

### 3. Cosmos DB
- NoSQL API, serverless capacity mode, session consistency
- Database: `word-game`
- Containers with access-pattern-driven partition keys:
  - `users` — partition key: `/id` — stores user profiles
  - `games` — partition key: `/id` — stores game state (use singleton control doc `active-game` for single-game lock)
  - `scores` — partition key: `/userId` — per-user scoring for leaderboard queries
  - `category_config` — partition key: `/id` — category URL configuration
- Private endpoint on private-endpoints subnet

### 4. Azure Container Registry
- Basic SKU (dev)
- User-assigned managed identity with AcrPull role on Container Apps
- Private endpoint on private-endpoints subnet (upgrade to Premium SKU if needed for private endpoints, otherwise skip PE for Basic)

### 5. Key Vault
- Standard SKU, RBAC access (Key Vault Secrets User for managed identity)
- Store: Cosmos connection string, Foundry endpoint/key, Entra client IDs
- Private endpoint on private-endpoints subnet

### 6. Azure AI Foundry
- AI Foundry project (hub + project)
- GPT-4.1-mini model deployment (or equivalent)
- Managed identity access for agent Container App
- If no AVM exists for AI Foundry, use native azurerm resources and log the exception

### 7. Monitoring
- Log Analytics workspace with daily cap (e.g., 1 GB/day for dev)
- Application Insights connected to Log Analytics
- Diagnostic settings on Container Apps, Cosmos DB

### 8. Identity
- User-assigned managed identity for Container Apps
- RBAC roles: AcrPull (ACR), Cosmos DB Data Contributor (Cosmos), Key Vault Secrets User (Key Vault), Cognitive Services User (Foundry)
- OIDC federation for GitHub Actions (for CI/CD deployment)

### 9. Entra External ID (via AZ CLI in scripts or null_resource)
- App registration for web (SPA, public client, redirect URIs)
- App registration for API (exposed scope: `access_as_user`)
- Self-service sign-up user flow
- Output client IDs and tenant info as Terraform outputs for consumption by other repos

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
