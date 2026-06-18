# Word Game Infrastructure

This repository contains the core infrastructure-as-code for the Word Game application using Terraform.

## Infrastructure Overview

- **Terraform Backend**: Azure Storage (remote state)
- **Cloud Provider**: Microsoft Azure
- **Deployment Model**: Manual (no CI/CD pipeline)
- **Primary Resources**: Container Apps, Cosmos DB, Azure AI, Azure Container Registry, Key Vault, networking

## Manual Deployment Process

This repository does **NOT** have a CI/CD pipeline. Infrastructure changes are applied manually by platform engineers.

### Prerequisites

- Azure CLI (`az`) installed and authenticated
- Terraform installed (v1.x or later)
- Proper Azure subscription context selected
- Required Azure permissions for resource creation/modification

### Deployment Steps

1. **Authenticate with Azure**:
   ```bash
   az login
   az account set --subscription "<subscription-id>"
   ```

2. **Initialize Terraform** (if first time or backend changes):
   ```bash
   terraform init
   ```

3. **Review Infrastructure Changes**:
   ```bash
   terraform plan -out=tfplan
   ```
   Review the plan output carefully to ensure changes match expectations.

4. **Apply Infrastructure Changes**:
   ```bash
   terraform apply tfplan
   ```
   Terraform will apply the planned changes to Azure resources.

5. **Verify Deployment**:
   - Check Azure Portal for resource creation/updates
   - Validate Container App endpoints are accessible
   - Verify data stores (Cosmos DB) are provisioned and healthy
   - Check networking (VNets, firewalls) connectivity

### State Management

- **Backend**: Azure Storage (configured in `providers.tf`)
- **Locking**: Enabled via Azure Storage backend
- **Local State**: `.tfstate` and `.tfstate.backup` files (excluded from git)

### Container App Deployment Architecture

**Important**: Container App resources are **split from this infrastructure repository**. Each service maintains its own deployment pipeline:

- **word-game-infra** (this repo): Manages shared infrastructure (networking, data stores, identity, key vault, AI services)
- **Per-service deployment**: Each microservice's CI/CD workflow creates and manages its own Container App using the Azure CLI (`az containerapp` commands)
- **Service discovery**: Services communicate through Container Apps Environment networking

This separation allows:
- Independent service deployment cycles
- Service-specific CD pipelines
- Reduced infrastructure coupling
- Clear separation of concerns

### Terraform Files

- `providers.tf` - Azure provider and backend configuration
- `versions.tf` - Terraform version constraints
- `variables.tf` - Input variables
- `locals.tf` - Local values
- `outputs.tf` - Output values
- `networking.tf` - VNets, subnets, firewalls, DNS
- `identity.tf` - Managed identities, RBAC
- `key-vault.tf` - Key Vault and secrets
- `cosmos.tf` - Cosmos DB configuration
- `ai-foundry.tf` - Azure AI Foundry setup
- `container-apps.tf` - Container Apps environment (shared infrastructure only)
- `monitoring.tf` - Azure Monitor and Log Analytics
- `state-migrations.tf` - State and migration infrastructure

### Troubleshooting

- **State Lock Issues**: If a deployment is interrupted, manually unlock state in Azure Storage if needed
- **Terraform Drift**: Run `terraform plan` periodically to detect infrastructure drift
- **Azure CLI Auth**: Ensure `az` CLI is authenticated: `az account show`
- **Subscription Context**: Verify correct subscription: `az account list --output table`

### Development Workflow

1. Create a feature branch for changes
2. Make Terraform modifications
3. Run `terraform fmt` to format code
4. Validate with `terraform init && terraform validate`
5. Create a pull request (for code review even though CI/CD doesn't auto-apply)
6. After approval, manually apply changes following the deployment steps above

### Notes

- All infrastructure changes are manual and should be carefully reviewed
- Keep Terraform state synchronized across team members
- Document any out-of-band Azure changes for future reference
