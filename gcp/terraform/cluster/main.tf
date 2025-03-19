locals {
  project_id = "fc3-deploy"
  region     = "us-central1"
}

resource "google_compute_network" "vpc" {
  name                    = "${local.project_id}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${local.project_id}-subnet"
  region        = local.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_container_cluster" "gke" {
  name     = "fc3"
  location = local.region

  enable_autopilot = true

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  deletion_protection = false
}