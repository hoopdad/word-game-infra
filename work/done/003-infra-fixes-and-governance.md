# Work Request: Infrastructure Fixes, AVM Enforcement, Container App Split

**Requirement:** `.requirements/deployment-updates.yml`
**Contradictions:** `.requirements/contradictions-report.md`
**CI/CD Analysis:** `.requirements/cicd-dependency-analysis.md`
**Platform Guardrails:** `.requirements/platform-guardrails.yml`

## Context

Terraform apply produces multiple errors (see `tf-err.txt` in harness). This request fixes all errors, enforces AVM-first patterns, splits container app resources out of infra, and adds missing governance files.

## Acceptance Criteria

### 1. Fix Terraform Errors

#### 1a. GPT-4.1-mini SKU (ai-foundry.tf)
- Change the `azurerm_cognitive_deployment.gpt_41_mini` SKU from `Standard` to `GlobalStandard`
- The `GlobalStandard` SKU is confirmed available in Central US for gpt-4.1-mini

#### 1b. Foundry Project (ai-foundry.tf)
- The `azapi_resource.foundry_project` fails because the cognitive account needs `allowProjectManagement` set to `true`
- The account `kind` must be `"AIServices"` (it already is)
- Add the `allowProjectManagement = true` property to the cognitive account configuration
- For the azapi_resource, verify the API version and resource type are correct for AI Foundry projects

#### 1c. Key Vault Access (key-vault.tf)
- Terraform cannot access Key Vault due to private networking: "bypass is not set to 'AzureServices' and PublicNetworkAccess is set to 'Disabled'"
- Fix: Configure Key Vault AVM module to set `network_acls.bypass = "AzureServices"` while keeping public access disabled
- **Additionally:** Ensure the self-hosted runner has private network access to Key Vault (it must be on the VNet or have DNS/route to the private endpoint)
- **RBAC:** The deployer identity needs `Key Vault Secrets Officer` role (not just `Secrets User`) to create/update secrets during terraform apply
- If the runner cannot reach the private endpoint, temporarily enable public access with IP allow-list for the runner during apply, then disable after

#### 1d. Key Vault Secret Arguments (key-vault.tf)
- The `foundry_key` secret fails with: `"value": one of value,value_wo must be specified`
- This is an azurerm provider v4.x issue where `value` and `value_wo` are mutually exclusive
- Fix: Use `value_wo` for the foundry key secret (it's a sensitive value that should use write-only)
- Also add `value_wo_version` parameter as required by the provider

#### 1e. Cosmos DB Role Assignment (identity.tf)
- The role `Cosmos DB Built-in Data Contributor` is NOT an Azure RBAC role — it's a Cosmos DB built-in data-plane role
- Replace `azurerm_role_assignment.cosmos_data_contributor` with `azurerm_cosmosdb_sql_role_assignment`
- The built-in role definition ID for Cosmos DB data contributor is: `00000000-0000-0000-0000-000000000002`
- Scope it to the Cosmos DB account, assign to the user-assigned managed identity

#### 1f. Shell Compatibility (entra.tf → REMOVE)
- The `null_resource.external_id_signup_flow` uses `set -euo pipefail` but runs under `/bin/sh` which doesn't support `-o pipefail`
- **REMOVE all Entra resources from entra.tf entirely** — Entra setup is now done via a local script (`scripts/setup-entra.sh` in the harness)
- Delete `entra.tf` completely
- Remove any outputs or references to Entra resources from `outputs.tf`
- Keep variables that might be needed for Entra client IDs as inputs (they'll be provided by the setup script)

#### 1g. Subnet Delegation — VERIFY
- The error says subnets must be delegated to `Microsoft.App/environments`
- The code in `networking.tf` already has delegation blocks on subnets
- Verify the delegation is on the correct subnet (the one referenced by `azurerm_container_app_environment`)
- If the AVM VNet module is being used, ensure the delegation is passed correctly through the module interface
- Check that both `internal` and `edge` Container App Environments reference delegated subnets

### 2. Split Container App Resources Out

- **REMOVE** all `azurerm_container_app` resources from `container-apps.tf`:
  - `azurerm_container_app.web`
  - `azurerm_container_app.api`
  - `azurerm_container_app.agent`
  - `azurerm_container_app.waf`
  - Associated diagnostic settings for individual apps
- **KEEP** in `container-apps.tf`:
  - `azurerm_container_app_environment.internal`
  - `azurerm_container_app_environment.edge`
  - Environment-level diagnostic settings
- **ADD** outputs for the Container App Environment IDs and default domains so service CD workflows can reference them
- Service container apps will now be created by each repo's CD workflow using `az containerapp create`

### 3. Enforce AVM Preference

- Currently using AVM for: VNet, Cosmos DB, ACR, Key Vault, Log Analytics
- Verify no AVM exists for: Container App Environment, AI Foundry/Cognitive Services, Identity
- If an AVM exists for any of these, migrate to it
- If no AVM exists, that's acceptable (record in the note below)

### 4. Add Missing Governance Files

#### 4a. Create `.github/agents/word-game-infra-specialist.agent.md`
Follow the pattern from other repos but adapted for infra:
- Role: Infrastructure specialist for Terraform IaC
- Stack: Terraform / azurerm provider >= 4.0 / Azure Verified Modules
- Validation commands:
  - Lint: `terraform fmt -check -recursive`
  - Test: `terraform validate` (after `terraform init`)
  - Security: `checkov -d . --framework terraform --quiet`
  - Build: `terraform plan -out=tfplan` (when credentials available)
- Must enforce AVM-first approach: "Always prefer Azure Verified Modules (AVM) for any Azure resource. Only use native azurerm resources when no AVM exists. If no AVM exists, note the exception."
- Reference platform guardrails and requirements
- Include MCP tool usage instructions (terraform-local, azure-inspector, lint-local, security-scanner)

#### 4b. Create `.github/agents/word-game-infra-critic.agent.md`
Follow the pattern from other repos:
- Reviews specialist work for correctness, security, and guideline compliance
- Checks AVM usage
- Validates naming conventions: `{project}-{env}-{resource}`
- Ensures private networking, managed identities, no public endpoints

#### 4c. Create `.github/copilot-instructions.md`
Include:
- Repo purpose and stack
- Reference to agent files
- Reference to platform guardrails
- AVM-first mandate
- Naming convention: `wordgame-{env}-{resource}`
- Common tags: project, environment, managed_by, repository
- Central US region constraint
- MCP tools available and when to use them

### 5. Add CI/CD Workflows

#### 5a. Create `.github/workflows/ci.yml`
- Trigger: push to main, pull_request
- Runner: `self-hosted`
- Jobs with `needs:` ordering:
  1. `fmt-check`: `terraform fmt -check -recursive`
  2. `validate` (needs fmt-check): `terraform init -backend=false && terraform validate`
  3. `security-scan` (needs validate): `checkov -d . --framework terraform --quiet --soft-fail`
  4. `plan` (needs security-scan): `terraform plan` (on push to main only, with OIDC auth)

#### 5b. Create `.github/workflows/cd.yml`
- Trigger: `workflow_run` after CI on main
- Concurrency: `concurrency: { group: deploy-infra, cancel-in-progress: false }`
- Runner: `self-hosted`
- Gate: `github.event.workflow_run.conclusion == 'success'`
- Auth: OIDC using secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- Environment variables: `ARM_USE_OIDC=true`, `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`
- Backend: Azure Storage backend for state. Use secrets: `TF_BACKEND_RESOURCE_GROUP`, `TF_BACKEND_STORAGE_ACCOUNT`, `TF_BACKEND_CONTAINER`, `TF_BACKEND_KEY`
- Steps:
  1. Checkout at `workflow_run.head_sha`
  2. Azure login via OIDC
  3. `terraform init -backend-config=...` (using backend secrets)
  4. `terraform plan -out=tfplan`
  5. `terraform apply tfplan`
  6. Output Container App Environment names/IDs for downstream use

## Pattern Constraints (binding)
- Use Azure Verified Modules (AVM) for all resources where an AVM exists
- Terraform azurerm provider >= 4.0
- All resources in Central US region
- Private networking with VNet, private endpoints, and NSGs
- Cosmos DB NoSQL serverless with session consistency
- Azure Container Apps consumption plan with VNet integration
- ACR Basic SKU (dev) with managed identity pull
- Key Vault Standard SKU with RBAC
- Azure AI Foundry project with GPT-4.1-mini deployment (GlobalStandard SKU)
- User-assigned managed identity for Container Apps
- Log Analytics workspace with daily cap

## Notes
- Entra resources are intentionally removed — they are managed by `scripts/setup-entra.sh` in the harness repo
- Container app resources are intentionally removed — they will be managed by each service's CD workflow
- The specialist agent instructions MUST explicitly mandate AVM-first approach

## Implementation Summary (Specialist)

Completed all requested infra/governance updates in this repo:

1. **Terraform error fixes**
   - Migrated AI Foundry account/deployment to AVM (`Azure/avm-res-cognitiveservices-account`) with:
     - `kind = "AIServices"`
     - `allow_project_management = true`
     - GPT-4.1-mini deployment scale type set to `GlobalStandard`
   - Kept Foundry project as `azapi_resource` with verified type/version:
     - `Microsoft.CognitiveServices/accounts/projects@2025-06-01`
   - Updated Key Vault AVM config to:
     - `public_network_access_enabled = false`
     - `network_acls = { bypass = "AzureServices", default_action = "Deny" }`
   - Updated Foundry key secret to provider-v4-compatible write-only form:
     - `value_wo` + `value_wo_version`
   - Replaced Cosmos RBAC assignment with data-plane assignment:
     - `azurerm_cosmosdb_sql_role_assignment`
     - built-in role definition ID `...0002`
   - Removed all Entra Terraform resources by deleting `entra.tf`.
   - Removed Entra outputs and retained Entra client IDs as Terraform input variables.
   - Updated deployer RBAC to `Key Vault Secrets Officer` for secret write operations.

2. **Container Apps split**
   - Removed all `azurerm_container_app` app resources and app-level diagnostics.
   - Kept only Container App Environment infrastructure (internal + edge) with environment-level diagnostic settings.
   - Added outputs for environment IDs, names, and default domains.
   - Service app deployment remains delegated to service CD workflows.

3. **AVM preference enforcement**
   - Verified AVM availability and migrated where available for:
     - Container App Environment
     - Cognitive Services / AI Foundry account
     - User-assigned managed identity
   - Logged remaining justified non-AVM usage in `.decisions/log.md`.

4. **Governance files**
   - Updated specialist and critic agent instructions with AVM-first gates, validation commands, guardrail references, and MCP guidance.
   - Added `.github/copilot-instructions.md` with stack, standards, naming/tags, region constraint, and MCP usage.

5. **CI/CD workflows**
   - Added `.github/workflows/ci.yml` with ordered jobs:
     - `fmt-check` -> `validate` -> `security-scan` -> `plan` (push to main only)
   - Added `.github/workflows/cd.yml` triggered by successful CI workflow run on main, with OIDC auth, backend-config init, plan/apply, and Container App Environment output emission.

6. **Validation**
   - `terraform fmt -check -recursive` ✅
   - `terraform init -backend=false && terraform validate` ✅
   - `terraform plan -out=tfplan` ✅
   - `checkov -d . --framework terraform --quiet` executed; baseline policy findings remain (module source pinning and existing platform policy checks), while CI is configured with `--soft-fail` per requirement.

Operational prerequisite reminder from request 1c:
- Self-hosted runners executing apply must have private DNS/routing reachability to Key Vault private endpoints (or temporarily use controlled public allow-list access during apply windows).

## Critic PASS Rationale

PASS — request 003 satisfies acceptance criteria and queue protocol:

1. **Terraform fixes verified in code**
   - Foundry deployment uses `GlobalStandard` and project management is enabled on AI account.
   - Foundry project remains valid `azapi_resource` with current `accounts/projects@2025-06-01` type.
   - Key Vault uses `network_acls.bypass = "AzureServices"` with public access disabled.
   - Foundry key secret is corrected to `value_wo` + `value_wo_version`.
   - Cosmos data-plane assignment is implemented with `azurerm_cosmosdb_sql_role_assignment` and built-in role definition ID `...0002`.
   - Entra Terraform resources are removed (`entra.tf` deleted) and Entra outputs removed.

2. **Container app split and delegation**
   - Service `azurerm_container_app` resources and per-app diagnostics are removed from infra.
   - Internal and edge Container App Environments remain as infra-owned primitives with environment diagnostics.
   - Both environments reference delegated subnets via AVM-managed environment modules:
     - internal -> `container_apps` subnet
     - edge -> `ingress` subnet

3. **AVM/governance/workflow requirements**
   - AVM-first posture strengthened, including migrations for CAE, AI account/deployment, and user-assigned identity.
   - Specialist and critic agent files include required AVM-first and validation guidance.
   - `.github/copilot-instructions.md` added with naming/tagging/region/tool guidance.
   - CI/CD workflows added with required ordering, OIDC auth flow, remote backend init in CD, and CAE output emission.

4. **Validation evidence**
   - `terraform fmt -check -recursive`, `terraform validate`, and `terraform plan -out=tfplan` succeeded.
   - Checkov execution recorded with baseline findings and CI soft-fail behavior as requested.
