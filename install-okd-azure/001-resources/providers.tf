# Configure the Azure provider
terraform {
  required_version = ">= 1.1.0"
  #backend "local" { path = "./terraform.tfstate" }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "> 3.50.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  tenant_id = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}

provider "azurerm" {
  features {}

  # reference by azurerm.default
  alias = "default"

  tenant_id = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}
