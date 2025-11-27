# YC Capstone - Minimal Production Web App on Azure

Author: Amrish Kumar

This repository contains:

- Infra (Terraform) for:
  - Resource Group, VNet and subnets
  - Storage Account with static website hosting
  - Key Vault with a db-conn secret
  - Log Analytics workspace
  - A sample subscription budget (optional)
- App - simple static website (HTML + CSS)
- GitHub Actions pipeline to deploy the static site to Azure Storage on push to main
- Runbook - deploy/rollback/troubleshooting
- Lessons Learned notes
- Architecture diagrams - PNGs under infra/diagrams/

## Repository structure

```text
.
├── infra/
│   ├── diagrams/
│   │   ├── compute-decision.md
│   │   ├── compute-decision.png
│   │   ├── network-architecture.md
│   │   ├── network-architecture.png
│   │   ├── resource-model.md
│   │   └── resource-model.png
│   └── week7-8/
│       └── infra-tf/
│           ├── backend.tf.example
│           ├── main.tf
│           ├── outputs.tf
│           ├── README.md
│           ├── terraform.tfvars    # local, ignored by git
│           ├── terraform.tfvars.example
│           ├── variables.tf
│           └── WORKFLOW_DOCS.md
├── app/
│   ├── index.html
│   └── styles.css
├── .github/
│   └── workflows/
│       └── deploy-static-website.yml
├── screenshots/
│   ├── aleart.png
│   ├── alert-rule.png
│   ├── pipeline.png
│   └── static_website.png
├── runbook/
│   └── runbook.md
├── lessons-learned.md
└── README.md
```

## How to use

1. Open infra/week7-8/infra-tf/terraform.tfvars and replace placeholder IDs with your real values.
2. Run Terraform locally OR push this repo to GitHub and let the workflow run.
3. After apply, get the static site URL via:

   cd infra/week7-8/infra-tf
   terraform output static_website_url

4. Update this README with your live URL:

Live URL: https://amrishterraformblob.z13.web.core.windows.net/
