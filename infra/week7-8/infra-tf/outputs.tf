output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group."
}

output "storage_account_name" {
  value       = azurerm_storage_account.static_site.name
  description = "Storage account name."
}

output "static_website_url" {
  value       = azurerm_storage_account.static_site.primary_web_endpoint
  description = "Static website URL."
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "Key Vault URI."
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.law.id
  description = "Log Analytics workspace id."
}
