terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.32"
    }
  }
  required_version = "~> 1.11"
}
provider "google" {
  project = var.project_id
  region  = var.regions[0]
}
