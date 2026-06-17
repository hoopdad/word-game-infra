# Decision Log

## 2026-06-17

- **AI Foundry hub/project provisioning:** No stable Azure Verified Module was used for AI Foundry hub/project at scaffold time. Terraform uses native `azurerm` resources for Azure AI account/deployment plus `null_resource` + Azure CLI for hub/project bootstrap.
- **Entra External ID user flow provisioning:** No AVM exists for Entra External ID user flows. Terraform uses `null_resource` + Microsoft Graph via Azure CLI.
