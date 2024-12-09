terraform {
  required_version = "~> 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }

  backend "gcs" {
    bucket = "codeflix-terraform"
    prefix = "states/terraform.cluster.tfstate"
  }
}

provider "google" {
  project = "fc3-deploy"
  region  = "us-central1"
}
