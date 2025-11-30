# GitHub Actions Terraform Deployment Setup

This guide explains how to configure GitHub Actions to automatically deploy your Terraform code to Azure.

## Prerequisites

- Azure subscription
- Service Principal with appropriate permissions
- GitHub repository

## Step 1: Create an Azure Service Principal

Run these commands in Azure CLI to create a service principal:

```bash
# Set your subscription ID
SUBSCRIPTION_ID="your-subscription-id"

# Create service principal
az ad sp create-for-rbac --name "github-terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID

# Output will include:
# - appId (CLIENT_ID)
# - password (CLIENT_SECRET)
# - tenant (TENANT_ID)
```

## Step 2: Add GitHub Secrets

Add the following secrets to your GitHub repository:

1. Go to **Settings → Secrets and variables → Actions**
2. Click **New repository secret** and add each:

| Secret Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | Service Principal App ID |
| `AZURE_CLIENT_SECRET` | Service Principal Password |
| `AZURE_SUBSCRIPTION_ID` | Your Azure Subscription ID |
| `AZURE_TENANT_ID` | Your Azure Tenant ID |

## Step 3: Configure Terraform Remote State (Optional but Recommended)

For production use, store Terraform state in Azure Storage:

```bash
# Create storage account for state
az storage account create \
  --name "tfstate$(date +%s)" \
  --resource-group "your-rg" \
  --location "East US" \
  --sku Standard_LRS

# Create container
az storage container create \
  --name tfstate \
  --account-name your-storage-account-name

# Get storage account key
az storage account keys list \
  --account-name your-storage-account-name \
  --query '[0].value' -o tsv
```

Then add to `backend.tf`:

```terraform
terraform {
  backend "azurerm" {
    resource_group_name  = "your-rg"
    storage_account_name = "your-storage-account"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
  }
}
```

## How It Works

### On Pull Request
- Runs `terraform init`, `terraform validate`, and `terraform fmt`
- Runs `terraform plan` and posts the output in PR comments
- Does NOT apply changes

### On Push to Main
- Runs all validation steps
- Runs `terraform plan`
- Automatically runs `terraform apply`
- Detects infrastructure drift

### Drift Detection
- Runs nightly to detect unintended infrastructure changes
- Alerts if drift is detected

## Workflow Triggers

The workflow runs when:
- **Push to main branch**: With `*.tf` file changes
- **Pull request to main**: With `*.tf` file changes
- **Manual trigger**: Via GitHub Actions UI

## Security Best Practices

✅ **Implemented**
- Secrets stored securely in GitHub
- Service Principal with minimal required permissions
- Plan artifacts retained for 5 days
- PR comments for transparency

📋 **Additional Recommendations**
- Rotate Service Principal credentials regularly
- Use Azure RBAC for environment-specific permissions
- Enable branch protection rules requiring PR reviews
- Use separate service principals per environment
- Consider Terraform Cloud for state locking

## Troubleshooting

**Issue**: Authentication failures
- Verify all secrets are set correctly
- Check Service Principal has Contributor role

**Issue**: Plan step fails
- Check Terraform syntax: `terraform validate` locally
- Verify Azure credentials have resource group access

**Issue**: Apply not triggering
- Ensure push is to `main` branch
- Verify `*.tf` files were modified

## Environments (Advanced)

To manage multiple environments (dev, staging, prod):

```yaml
# Create .github/workflows/terraform-deploy-prod.yml
# with prod-specific variables and branch rules
```

For detailed examples, see the workflow file: `.github/workflows/terraform-deploy.yml`
