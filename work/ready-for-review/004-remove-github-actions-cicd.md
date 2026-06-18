# Work Request: Remove GitHub Actions OIDC Terraform Vestiges

**Requirement:** `/home/mike/source/word-game/word-game-harness/.requirements/cicd.yml`
**Platform Guardrails:** `/home/mike/source/word-game/word-game-harness/.requirements/platform-guardrails.yml`

## Context

The project is moving from GitHub Actions CI/CD to local `azd up` orchestration from `word-game-harness`. Remove the remaining Terraform references to GitHub Actions OIDC or service-principal deployment identities. Do not disturb the runtime managed identity used by Container Apps.

## Acceptance Criteria

1. Remove any Terraform resources, state migrations, variables, or references related to GitHub Actions deployment identity, including if present:
   - `azuread_application` for GitHub Actions / CI-CD
   - `azuread_application_federated_identity_credential`
   - `azuread_service_principal`
   - role assignments created only for the GitHub Actions service principal
   - OIDC-specific Terraform state migration remnants
2. Remove `github_repository` and `github_branch` if they are only used for the deleted OIDC model; if there is a compelling reason to keep one, clearly mark it deprecated.
3. Do **not** remove or alter the runtime managed identity for Container Apps, including these required assignments:
   - `AcrPull`
   - Cosmos DB data contributor assignment for the managed identity
   - `Key Vault Secrets User`
   - `Cognitive Services User`
4. Run the smallest existing Terraform validation that covers the change, at minimum:
   - `terraform fmt -check -recursive`
   - `terraform init -backend=false`
   - `terraform validate`
5. Commit the repo changes on `feature/azd-deploy` with exactly:

```text
refactor: remove GitHub Actions CI/CD in favor of local azd deploy

Removes workflow files and OIDC federation. Deployment now handled by
azd up from word-game-harness with local terraform state.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

## Validation

- Confirm no remaining Terraform references to GitHub Actions OIDC resources or variables.
- Confirm managed-identity runtime role assignments remain intact.
- Ensure `git status --short` is clean after the commit.

## Critic Gate

Return `STATUS: PASS` only if OIDC vestiges are gone, managed-identity runtime access is preserved, Terraform validation passes, and the required commit exists.

## Specialist Implementation Summary

- Removed Terraform OIDC vestiges:
  - deleted `github_repository` and `github_branch` variables from `variables.tf`
  - removed `cicd_app_registration` local from `locals.tf`
  - removed OIDC-specific state-removal block for `azuread_application.github_actions` from `state-migrations.tf`
- Removed obsolete GitHub Actions CI/CD artifacts tied to OIDC deployment:
  - deleted `.github/xworkflows/ci.yml`
  - deleted `.github/xworkflows/cd.yml`
  - deleted `scripts/setup-oidc.sh`
- Preserved runtime managed identity and required assignments in `identity.tf`:
  - `AcrPull`
  - Cosmos DB SQL data contributor assignment (`azurerm_cosmosdb_sql_role_assignment.cosmos_data_contributor`)
  - `Key Vault Secrets User`
  - `Cognitive Services User`
- Ran required Terraform validation commands successfully:
  - `terraform fmt -check -recursive`
  - `terraform init -backend=false -input=false`
  - `terraform validate`
