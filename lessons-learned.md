# Lessons Learned – YC Capstone

Author: Amrish Kumar

1. **Terraform + Azure**  
   - Using Terraform made it easier to recreate the same environment repeatedly.
   - Learned how to structure variables, outputs, and tags to keep infra consistent.

2. **Security & Governance**  
   - Centralizing secrets in Key Vault is safer than using connection strings directly.
   - Tags are helpful for grouping resources by owner, env, and cost center.

3. **CI/CD**  
   - GitHub Actions can directly deploy static websites to Azure Storage.
   - Storing credentials in GitHub Secrets keeps the pipeline secure.

4. **Observability & Cost**  
   - Log Analytics is the foundation for many observability features.
   - Budgets and alerts help prevent surprise bills, even for small labs.

5. **Cloud Mindset**  
   - Everything (infra, config, deploy) can be treated as code.
   - Small, simple setups can still be designed with production-style practices in mind.

