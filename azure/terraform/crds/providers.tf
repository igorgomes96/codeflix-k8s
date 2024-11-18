terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.10.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
  }

  backend "azurerm" {
    resource_group_name  = "fullcycle-terraform-rg"
    storage_account_name = "fcremotestatetf"
    container_name       = "tfstate"
    key                  = "terraform.crds.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "fffde95a-cf63-45fa-973a-5051457297c6"
  features {}
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}