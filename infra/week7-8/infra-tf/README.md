# Infra - Week 7-8 Capstone (Terraform)

This folder contains Terraform code for the YC Capstone minimal production-style environment.

Resources:

- Resource Group - yc-capstone-rg
- VNet - yc-vnet with web and data subnets
- NSG - web-nsg attached to web subnet
- Storage Account - static website enabled
- Key Vault - holds db-conn secret
- Log Analytics workspace
- Optional subscription budget (may require extra permissions)

Usage (local):

  terraform init
  terraform plan -out tfplan
  terraform apply tfplan

Destroy:

  terraform destroy

If budget creation fails due to permissions, comment out the azurerm_consumption_budget_subscription resource in main.tf.

Remote state & CI notes
-----------------------

1. Remote backend: it's recommended to use a remote backend for Terraform state (Azure Storage account + container). See `backend.tf.example` for a sample configuration — copy to `backend.tf` and update names before running `terraform init`.

2. CI safety: this repository's GitHub workflow now separates `plan` and `apply`. The `apply` job is gated by a GitHub Environment called `production` which should require a manual approval (or set required reviewers). This prevents `terraform apply` from running automatically on every push to `main`.

3. Secrets: do not commit any secrets (db connection strings, client secrets) into this repo. Use GitHub secrets, Azure Key Vault, or environment variables in CI.

How to provide variables safely
-------------------------------

- Local development (developer machine):
  - Copy the example file and edit it locally:

    ```bash
    cp terraform.tfvars.example terraform.tfvars
    # then edit terraform.tfvars and fill real values
    ```

  - `terraform.tfvars` is ignored by the repository (`*.tfvars` is in `.gitignore`). Do not commit it.

- CI (GitHub Actions) — recommended for production:
  - Store credentials and environment values as GitHub repository Secrets (or use OIDC/workload identity):
    - `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
  - The workflow authenticates to Azure and Terraform will use those credentials. `data.azurerm_client_config.current` will reflect the authenticated tenant/subscription so you do not need to commit `tenant_id`.

- Key Vault approach (advanced):
  - Store sensitive values in Azure Key Vault and grant the Terraform service principal (used by CI) a `get` secret permission.
  - Read secrets at plan/apply time using `data.azurerm_key_vault_secret` if needed — be careful about sensitive values ending up in state.

Quick CI commands (workflow runs these inside `infra/week7-8/infra-tf`):

```bash
terraform init -input=false
terraform plan -out=tfplan -input=false
terraform apply -auto-approve tfplan
```

If you want, create a local `terraform.tfvars` from the example now and keep it private. For production, add values to GitHub Secrets and use the repository workflow.

4. CI workflow docs: a complete explanation of `.github/workflows/deploy-static-website.yml` and production rationale is available in `WORKFLOW_DOCS.md`.
