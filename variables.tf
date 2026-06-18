variable "subscription_id" {
  type        = string
  description = "Azure subscription ID used for deployment."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "centralus"
}

variable "environment" {
  type        = string
  description = "Deployment environment."
  default     = "dev"
}

variable "container_image_tag" {
  type        = string
  description = "Container image tag used for all apps."
  default     = "latest"
}

variable "log_analytics_daily_quota_gb" {
  type        = number
  description = "Daily ingestion cap (GB/day) for Log Analytics."
  default     = 1
}

variable "hub_subscription_id" {
  type        = string
  description = "Hub subscription ID for spoke peering and shared services."
  default     = ""
}

variable "hub_resource_group_name" {
  type        = string
  description = "Hub resource group name containing VNet and LAW."
  default     = ""
}

variable "hub_vnet_name" {
  type        = string
  description = "Hub VNet name for peering."
  default     = ""
}

variable "hub_law_name" {
  type        = string
  description = "Hub Log Analytics workspace name."
  default     = ""
}

variable "common_tags" {
  type        = map(string)
  description = "Optional extra tags merged into the default tagging set."
  default     = {}
}

variable "foundry_model_name" {
  type        = string
  description = "Model name for Azure AI deployment."
  default     = "gpt-4.1-mini"
}

variable "foundry_model_version" {
  type        = string
  description = "Model version for Azure AI deployment."
  default     = "2025-04-14"
}



variable "entra_web_client_id" {
  type        = string
  description = "External Entra web app client ID created outside Terraform."
  default     = ""
}

variable "entra_api_client_id" {
  type        = string
  description = "External Entra API app client ID created outside Terraform."
  default     = ""
}


variable "public_client_redirect_uris" {
  type        = list(string)
  description = "Redirect URIs for public client sign-in."
  default     = ["https://login.microsoftonline.com/common/oauth2/nativeclient"]
}
