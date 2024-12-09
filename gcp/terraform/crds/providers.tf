terraform {
  required_version = "~> 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
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

  backend "gcs" {
    bucket = "codeflix-terraform"
    prefix = "states/terraform.crds.tfstate"
  }
}

provider "google" {
  project = "fc3-deploy"
  region  = "us-central1"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}