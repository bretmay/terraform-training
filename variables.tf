variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string
  default     = "brets-terraform-rg"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
