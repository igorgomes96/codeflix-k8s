terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

  backend "s3" {
    bucket         = "codeflix-terraform"
    key            = "states/terraform.crds.tfstate"
    dynamodb_table = "tf-state-locking"
  }
}

provider "aws" {
  region = "us-east-2"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}