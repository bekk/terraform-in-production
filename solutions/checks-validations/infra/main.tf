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

check "workshop_project_is_used" {
  assert {
    condition     = var.project_id == "cloud-labs-workshop-42clws"
    error_message = "The provider should be using the cloud-labs-workshop. This check is a safety measure to prevent provisioning in other projects. If you're running in your own project, edit or delete this check."
  }
}

module "network" {
  source       = "../modules/network"

  subnets = {
    regions = var.regions
    cidrs   = var.subnet_cidrs
  }
  name_prefix  = var.name_prefix
}


# DNS resources
resource "google_dns_managed_zone" "private_zone" {
  name        = "${var.name_prefix}-private-zone"
  dns_name    = "workshop.internal."
  description = "Private DNS zone for workshop"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = module.network.vpc_id
    }
  }
}

module "records" {
  count        = length(var.dns_records)
  source       = "../modules/dns_a_record"
  name         = "${var.dns_records[count.index]}.${var.name_prefix}.workshop.internal."
  zone_name    = google_dns_managed_zone.private_zone.name
  ipv4_address = "10.0.0.${10 + count.index}"
}


# IAM resources
resource "google_service_account" "service_accounts" {
  count        = length(var.service_accounts)
  account_id   = "${var.name_prefix}-${var.service_accounts[count.index]}"
  display_name = "Workshop ${var.service_accounts[count.index]} service account"
  description  = "Service account for ${var.service_accounts[count.index]} services"
}

resource "google_project_iam_member" "project_roles" {
  count   = length(var.project_roles) * length(google_service_account.service_accounts)
  project = var.project_id
  role    = var.project_roles[floor(count.index / length(var.service_accounts))]

  member = "serviceAccount:${google_service_account.service_accounts[count.index % length(google_service_account.service_accounts)].email}"
}

# Variables to support the above
variable "name_prefix" {
  description = "Prefix for resource names to ensure uniqueness"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "regions" {
  description = "Regions for subnets"
  type        = list(string)
  default     = ["us-central1", "us-east1", "us-west1"]
}

variable "subnet_cidrs" {
  description = "CIDR ranges for subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "dns_records" {
  description = "DNS record names"
  type        = list(string)
  default     = ["app", "db", "cache"]
}

variable "service_accounts" {
  description = "Service account names"
  type        = list(string)
  default     = ["app", "monitoring", "automation"]
}

variable "project_roles" {
  description = "IAM roles to assign"
  type        = list(string)
  default = [
    "roles/monitoring.viewer",
    "roles/logging.viewer"
  ]
}
