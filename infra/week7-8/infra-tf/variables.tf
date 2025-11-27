variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
  default     = "yc-capstone-rg"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "yc-app"
}

variable "storage_account_name" {
  description = "Globally unique Storage Account name."
  type        = string
  default     = "ycappstaticwebdemo"
}

variable "key_vault_name" {
  description = "Key Vault name."
  type        = string
  default     = "yc-kv-demo"
}

variable "kv_admin_object_id" {
  description = "Object ID of the user or service principal that can manage secrets."
  type        = string
}

variable "tags" {
  description = "Common tags for all resources."
  type        = map(string)
  default = {
    owner               = "amrish.kumar@example.com"
    env                 = "dev"
    cost_center         = "yc-capstone"
    app                 = "yc-static-web"
    data_classification = "internal"
  }
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount."
  type        = number
  default     = 10
}

variable "budget_start_date" {
  description = "Budget start date (YYYY-MM-DD)."
  type        = string
  default     = "2025-11-01"
}

variable "budget_end_date" {
  description = "Budget end date (YYYY-MM-DD)."
  type        = string
  default     = "2026-11-01"
}

variable "budget_contact_email" {
  description = "Email to receive budget alerts."
  type        = string
  default     = "amrish.kumar@example.com"
}
