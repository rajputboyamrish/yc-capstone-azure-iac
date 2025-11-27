# Runbook – YC Capstone Static Web App

Author: Amrish Kumar
Last updated: 2025-11-27

Maintainers / contacts:

- Owner: Amrish Kumar — amrishsrk23@gmail.com
- Escalation path: Level 1 — Developer on-call; Level 2 — Infra lead; Level 3 — CTO

---

## 1. Architecture & Dependencies

### 1.1. Components

- **Resource Group**: `yc-capstone-rg`
- **VNet**: `yc-vnet` with `web` and `data` subnets
- **Storage Account**: Static website enabled; hosts the app in `$web` container
- **Key Vault**: Stores `db-conn` secret (sample)
- **Log Analytics workspace**: Central log store
- **Budget**: Subscription-level monthly budget (example)
- **CI/CD**: GitHub Actions workflow `deploy-static-website.yml`

### 1.2. Dependencies

- Terraform CLI
- Azure subscription + permissions
- GitHub repo with:
  - `AZURE_CREDENTIALS`, `AZURE_SUBSCRIPTION_ID`,
    `AZURE_RESOURCE_GROUP`, `AZURE_STORAGE_ACCOUNT` secrets

---

## 2. Deploy Steps (IaC)

1. Clone the repo:

  ```bash
  git clone <YOUR_REPO_URL>
  cd infra/week7-8/infra-tf
  ```

2. Log in to Azure (for local Terraform):

   ```bash
   az login
   az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
   ```

3. Set required variables (you can use a `terraform.tfvars` file):

   ```hcl
   subscription_id     = "<YOUR_SUB_ID>"
   tenant_id           = "<YOUR_TENANT_ID>"
   kv_admin_object_id  = "<YOUR_OBJECT_ID>"
   storage_account_name = "<UNIQUE_LOWERCASE_NAME>"

  ### Required minimum versions

  - Terraform >= 1.3.0
  - az cli >= 2.45.0

   ```

4. Initialize and apply:

   ```bash
   terraform init
   terraform plan -out tfplan
   terraform apply tfplan
   ```

5. Note the outputs:

   ```bash
   terraform output
   ```

   Especially:

   - `static_website_url`
   - `storage_account_name`
   - `key_vault_uri`

---

## 3. Rollback Steps

Safer rollback / recovery (preferred)

If the site or a deploy is failing due to a bad commit or corrupted upload, prefer non-destructive recovery first:

1. Revert the bad commit(s) in the repo or roll back the build artifact in GitHub.
2. Re-run the GitHub Actions workflow for `main` (the workflow will overwrite files in `$web`).
3. Or manually upload a previously known-good build from a local copy or CI artifact:

```bash
az storage blob upload-batch -s ./app -d '$web' --account-name <storage_account>
```

To remove all created infra (use with care):

```bash
cd infra/week7-8/infra-tf
terraform destroy
```

Confirm when prompted.

> **Recommendation:**  
> Destroy dev/test environments when not needed to avoid unnecessary charges.

---

## 4. Secrets Handling

- The DB connection string is stored as `db-conn` in Key Vault.
- Application code should never hardcode secrets.
- Retrieve secrets via:
  - Azure CLI (for testing),
  - Managed Identity (for real apps, if using App Service/VM in future).

### GitHub Actions / AZURE_CREDENTIALS and permissions

- `AZURE_CREDENTIALS` should be a JSON string matching the Azure SP used by Actions:

```json
{"clientId":"<CLIENT_ID>","clientSecret":"<CLIENT_SECRET>","subscriptionId":"<SUB_ID>","tenantId":"<TENANT_ID>"}
```

- Minimum recommended permissions for the SP used by GitHub Actions (if Actions applies infra + deployments):
  - Storage Blob Data Contributor on the Storage Account (for uploading to `$web`)
  - Contributor on the Resource Group (when applying Terraform, only if CI runs Terraform)

- If Key Vault is used only for secret retrieval at runtime, grant `Key Vault Secrets User` RBAC or appropriate access policy to the principal.

**DO NOT** commit secrets, connection strings, or access keys to the repo.

---

## 5. Monitoring & Alert Response

### 5.1. Logs & Metrics

- Logs are sent to **Log Analytics workspace**.
- Use the Logs blade in Azure Portal to run KQL queries.

### Example KQL snippets for quick investigations

Storage access events in the last hour:

```kql
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where OperationName in ("GetBlob","PutBlob","DeleteBlob")
| sort by TimeGenerated desc
```

Check web file reads (hits to index.html):

```kql
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where Uri endswith '/index.html'
| summarize hits = count() by bin(TimeGenerated, 1m)
| render timechart
```

### 5.2. Budget Alert

- When spending exceeds 80% of the configured budget, an email should be sent to
  the configured `budget_contact_email`.
- This is primarily for **cost awareness** in the lab.

### 5.3. What to Do on Alert

- **Budget alert**:
  - Review active resources in the Portal.
  - Stop VMs / scale down SKUs.
  - Destroy non-essential environments via `terraform destroy`.

- **Availability / app-related alert** (if configured on top):
  - Check Storage Account health.
  - Verify that `$web` container has the correct files.
  - Redeploy via GitHub Actions if needed.

---

## 6. CI/CD Notes

- Whenever you push to `main`, the GitHub Actions workflow:
  - Logs into Azure.
  - Ensures static website is enabled.
  - Uploads files from `app/` into `$web`.

If the pipeline fails:

1. Open **GitHub → Actions**.
2. Review logs for the `deploy` job.
3. Common issues:
   - Wrong subscription ID or resource group in secrets.
   - Storage account name mismatch.
   - `AZURE_CREDENTIALS` not valid or lacking permissions.

  #### Useful triage steps when the pipeline fails

  1. Verify secrets in GitHub: `AZURE_CREDENTIALS`, `AZURE_SUBSCRIPTION_ID`, `AZURE_RESOURCE_GROUP`, `AZURE_STORAGE_ACCOUNT`.
  2. Test `AZURE_CREDENTIALS` locally:

  ```bash
  echo '$AZURE_CREDENTIALS' > creds.json
  az login --service-principal -u $(jq -r .clientId creds.json) -p $(jq -r .clientSecret creds.json) --tenant $(jq -r .tenantId creds.json)
  az account set --subscription $(jq -r .subscriptionId creds.json)
  ```

  3. Ensure the SP has Storage Blob Data Contributor role on the storage account used for deployment.

---

## 7. Basic Troubleshooting

- **Static site not loading**
  - Check the URL from Terraform output.
  - Make sure DNS/URL is correct and protocol is `https`.
  - Confirm `$web` contains `index.html`.

- **Terraform errors**
  - Verify you are logged in (`az login`).
  - Check `subscription_id`, `tenant_id`, and `kv_admin_object_id` values.
  - If `azurerm_consumption_budget_subscription` fails, comment it out temporarily.

- **Key Vault access denied**
  - Ensure the `kv_admin_object_id` matches your user or SPN.
  - Check that RBAC + access policy settings are correct for your lab.

  ---

  ## Terraform state / backend

  This project stores Terraform state in a remote backend (recommended) — ensure you document and check where your state is hosted.

  - Typical backend: Azure Storage account container (e.g., `tfstate` container) with the state file keyed by workspace.
  - Backups: Azure Storage will retain previous versions if versioning is enabled, or you can manually copy the state file as a backup.

  Restore steps (high level):

  1. Download the desired `.tfstate` from the backend.
  2. Replace the backend file (or use the Terraform `state` subcommands to import/restore resources).
  3. When restoring state, ensure the backend is locked/unlocked properly to avoid concurrent changes.

  If you need a specific runbook for restoring a particular resource, document the exact `az storage blob download` and `terraform state` commands for that resource.

  ## How to validate / test this runbook

  1. Walk through the Post-deploy verification checklist on a test environment and confirm each command works.
  2. Create a small lab incident (e.g., push a bad commit and roll back) and follow the recovery steps end-to-end.

  ## Quick reference / cheatsheet (copyable)

  - Check site HTTP status:

  ```bash
  curl -Is $(terraform output -raw static_website_url) | head -n1
  ```

  - List `$web` container blobs:

  ```bash
  az storage blob list --account-name <storage-account-name> --container-name '$web' -o table
  ```

---

## Repository layout & where to capture evidence

- Infra root: `infra/week7-8/infra-tf`
- App: `app/`
- Diagrams: `infra/diagrams/` (store resource model, network diagrams here)
- Screenshots & evidence: `screenshots/` (store `pipeline.png`, `static_website.png`, `alert.png`)

Expected submission artifacts (place in repo):

- Terraform files + example `terraform.tfvars` in `infra/`
- App files in `app/`
- Diagrams and screenshots as listed above

## Week-by-week evidence checklist (copyable)

Week 1 - Cloud & Identity (RG, RBAC)
- Create resource group: `az group create -n yc-basics-rg -l eastus`
- Add tags: `az group update --name yc-basics-rg --set tags.owner='amrish@example.com' env='dev' cost_center='C123'`
- RBAC proof: `az role assignment create --assignee <peer-UPN> --role Reader --scope /subscriptions/<sub>/resourceGroups/yc-basics-rg`

Week 2 - Networking
- Create VNet / subnets and NSGs; verify NSG rules: `az network nsg rule list --nsg-name web-nsg --resource-group yc-capstone-rg`
- Add network diagram: `infra/diagrams/network-diagram.png`

Week 3 - Compute
- Deploy Small VM and cloud-init for Nginx; validate endpoint: `curl -I http://<vm_public_ip>`

Week 4 - Storage
- Create storage + container + upload sample file; generate SAS & test upload/download:
  - `az storage container create --name sample --account-name <sa>`
  - `az storage blob upload --account-name <sa> -c sample -f ./app/index.html -n index.html`
  - `az storage container generate-sas --account-name <sa> --name sample --permissions rwl --expiry 2025-12-01T00:00Z -o tsv`

Week 5 - Database
- Create DB; restrict firewall to your IP; capture connection test with `sqlcmd`/`psql`:
  - `sqlcmd -S <server>.database.windows.net -U <user> -P '<password>' -Q "SELECT 1"`

Week 6 - Secrets & Config
- Create Key Vault, store secret `db-conn`, test retrieval:
  - `az keyvault secret set --vault-name <kv> -n db-conn --value '<conn-string>'`
  - `az keyvault secret show --vault-name <kv> -n db-conn`

Weeks 7-8 - IaC, CI/CD & Observability (Capstone)
- Apply Terraform and capture `terraform output -raw static_website_url`
- Deploy pipeline run screenshot: `screenshots/pipeline.png`
- Confirm site is live: `curl -Is $(terraform output -raw static_website_url) | head -n1` and capture `screenshots/static_website.png`
- Create alert; store screenshots `screenshots/alert.png`


End of runbook.
