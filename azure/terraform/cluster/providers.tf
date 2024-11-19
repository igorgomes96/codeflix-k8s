terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.10.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "fullcycle-terraform-rg"
    storage_account_name = "fcremotestatetf"
    container_name       = "tfstate"
    key                  = "terraform.cluster.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "fffde95a-cf63-45fa-973a-5051457297c6"
  features {}
}