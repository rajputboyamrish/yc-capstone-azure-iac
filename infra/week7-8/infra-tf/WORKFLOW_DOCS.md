# GitHub Actions: deploy-static-website.yml — full explanation

This document explains each section of `.github/workflows/deploy-static-website.yml` found in this repository, why it's written that way, and why the choices help protect production infrastructure and processes.

Use this as a go-to reference for:
- Understanding the pipeline steps and responsibilities
- Why we run format/validate/plan before apply
- Why `apply` is gated behind an environment approval
- How the deployment to the `$web` container is done safely

---

## High level pipeline goals

1. Ensure Terraform code is well-formed and consistent before changing infra.
2. Produce a reproducible plan for human review (the `plan` job).
3. Prevent accidental or automated destructive changes to production (gated `apply`).
4. Keep publishing of static assets and infra changes separate where appropriate.
5. Avoid exposing secrets or writing sensitive values into committed files.

These goals are reflected directly in the workflow structure described below.

---

## Workflow anatomy (top -> bottom)

### name: Terraform + Deploy Static Website

Human-friendly pipeline name — appears in the GitHub Actions UI.

### on: push

Triggers the workflow on pushes to `main` branch. In many teams, you might instead:
- Run `plan` on pull requests and `apply` only on merges to protected `main` with approvals.
- Use a `push` trigger for this repo because it is a simple capstone demo; in production you should be stricter (e.g., plan on PRs, apply only when PR is merged and approved).

### permissions

Permissions block grants the workflow the minimum tokens required to operate. For example:
- `id-token: write` is required for OIDC authentication flows (used by `azure/login` when exchanging GitHub OIDC tokens for Azure credentials).
- `contents: read` limits access to repo contents only.

Principle: explicit, minimal permissions reduce attack surface and make audits easier.

### env: shared variables

We set the commonly used environment variables for the pipeline using GitHub secrets:
- AZURE_RESOURCE_GROUP, AZURE_STORAGE_ACCOUNT, AZURE_SUBSCRIPTION_ID

Why: centralizing names here avoids repeating them in every job.
Note: The real credentials are stored in `secrets.AZURE_CREDENTIALS` which the `azure/login` action uses.

---

## JOB: plan — Terraform fmt / validate / plan

This job does three important checks and outputs an on-disk plan artifact:

1. terraform fmt -check -recursive
   - Why: enforces consistent style and avoids large formatting-only diffs in the future. In teams this keeps reviewer attention on logic changes.

2. terraform init + terraform validate
   - Why: ensure the code can initialize and Terraform can parse/validate the configuration before making any changes.

3. terraform plan -out=tfplan
   - Why: produce a binary plan representing exactly what changes Terraform will attempt. This artifacts is uploaded for the `apply` job.

Why this separation matters for prod:
- `plan` is the safest place to fail fast. If plan fails or contains unexpected destructive changes, humans should examine it before applying.

Security notes:
- We run the plan step under the same Azure credentials to validate permissions, but we do not apply changes yet. That reduces the blast radius of accidental pushes.

---

## JOB: apply — gated Terraform apply + static site publish

This job depends on `plan` and requires a GitHub environment called `production`. The environment is a GitHub feature that supports required reviewers and manual approvals.

Why gate apply behind an environment:
- Prevents automatic `terraform apply` executions when code is pushed directly or merged into `main`.
- Requires an explicit human approval (or a policy) which is critical for production safety when state changes may be destructive.

What the job does, and why:
1. terraform init
   - Ensure the working directory is initialized in the runner trust boundary. This is needed prior to apply.

2. terraform apply -auto-approve tfplan || terraform apply -auto-approve
   - We attempt to apply the `tfplan` produced earlier. The fallback `terraform apply -auto-approve` is present as a safety net if the artifact cannot be read (e.g., different runner). Prefer applying the uploaded plan when possible.

3. Ensure static website settings (az storage blob service-properties update)
   - This command explicitly ensures that the Storage Account has static website configuration active. Sometimes this setting can be important when the plan succeeded but did not alter static site settings.

4. az storage blob upload-batch --destination '$web' --source "app"
   - Use single-quoted '$web' to instruct the `az` CLI to use the literal container named `$web`. If you use double quotes or an unquoted $web it will expand as a shell variable (often empty), causing upload errors.

Why separate apply + upload?
- Applying infra and publishing app assets are related but distinct operations. The workflow applies infra first and then publishes the UI — that sequencing ensures the `$web` container and storage account exist/are configured before upload.

---

## Why all of this is important in production

1. Human review of changes: Terraform `plan` gives a clear, machine-precise description of intended changes. Production teams should review this plan for unexpected deletes, permission changes, or accidental drift.
2. Prevent 'blast radius' from accidental pushes: gating `apply` behind a GitHub environment with required approvers prevents a single `git push` from mutating production resources.
3. Make mistakes visible earlier: `fmt` and `validate` force basic quality checks and save reviewers time.
4. Least-privilege & secrets: The workflow stores sensitive values in GitHub Secrets (e.g., `AZURE_CREDENTIALS`) instead of hardcoding them. In production consider using a short-lived credential flow (OIDC) and minimizing the principal's permissions.
5. Artifact-based apply: producing a plan artifact ensures the exact planned changes are applied (avoid a plan/apply race where the code changed between plan and apply).

---

## Production hardening recommendations (next steps)

1. Use remote Terraform state (backend.tf) + state locking to avoid concurrent applies.
2. Limit the GitHub Actions service principal to the minimal RBAC roles required for the actions it performs (e.g., for apply on infra and a separate SP for uploads to Storage Blob Data Contributor). Avoid full subscription-level Contributor unless strictly necessary.
3. Use GitHub Environments with review requirements and, if available, SSO/approval by on-call distribution lists.
4. Add policy and security scanning (tfsec, checkov) to the `plan` job.
5. Consider requiring signed commits and branch protection rules for `main`.

---

## Troubleshooting & best-practices

- If your `apply` job cannot find `tfplan`, make sure the job is configured to consume the artifact uploaded by `plan` — or run `terraform plan -out=tfplan` inside `apply` in restricted scenarios.
- Ensure GitHub Actions runners have the right access to your secret store and any network-level access rules (for private backends).
- Prefer OIDC (azure/login action with OIDC) over long-lived client secrets where possible.

---

If you want, I can add automation to:
1. Add `tfsec`/`Checkov` scanning to `plan` job.
2. Create a `backend.bootstrap` script to create the storage account + container for Terraform state safely.

---

Document last updated: 2025-11-27
