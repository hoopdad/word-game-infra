# Copilot Instructions — word-game-infra

## Repository Purpose
This repository owns Terraform infrastructure for the Word Game platform on Azure, including networking, Container Apps environments, Cosmos DB, ACR, Key Vault, AI Foundry resources, identity, and monitoring.

## Stack
- Terraform
- `hashicorp/azurerm` provider `>= 4.0`
- Azure Verified Modules (AVM) first
- `azurerm` fallback, `azapi` last resort

## Agent References
- Specialist: `.github/agents/word-game-infra-specialist.agent.md`
- Critic: `.github/agents/word-game-infra-critic.agent.md`

## Platform and Guardrail References
- `.requirements/platform-guardrails.yml`
- `.requirements/deployment-updates.yml`
- `.requirements/cicd-dependency-analysis.md`
- `.requirements/contradictions-report.md`
- `.contracts/`

## Non-Negotiable Standards
- Always prefer AVM for Azure resources when available.
- If AVM is unavailable, document fallback decisions in `.decisions/log.md`.
- Region constraint: **Central US** (`centralus`) unless a requirement explicitly says otherwise.
- Use private networking, private endpoints, and managed identity-first access.
- Avoid public endpoints unless explicitly required.

## Naming and Tags
- Naming convention: `wordgame-{env}-{resource}`
- Common tags:
  - `project=word-game`
  - `environment={env}`
  - `managed_by=terraform`
  - `repository=word-game-infra`

## MCP Tools and When to Use Them
- `terraform-local`:
  - `terraform_fmt_check` for formatting gate
  - `terraform_init_validate` for init/validate gate
  - `terraform_plan_check` for deterministic plan gate
- `azure-inspector`:
  - `inspect_container_app` for ACA runtime checks
  - `inspect_cosmos_db` for database/container inventory
  - `inspect_acr` for repository/tag verification
- `lint-local`: run local lint wrappers where configured
- `security-scanner`: run checkov and dependency/security scanners before merge
