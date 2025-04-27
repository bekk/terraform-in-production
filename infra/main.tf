provider "google" {
  project = var.project_id
  region  = var.regions[0]
}

check "workshop_project_is_used" {
  assert {
    condition   = var.project_id == "cloud-labs-workshop-42clws"
    error_message = "The provider should be using the cloud-labs-workshop. This check is a safety measure to prevent provisioning in other projects. If you're running in your own project, edit or delete this check."
  }
}

# Network resources
resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-workshop-vpc"
  auto_create_subnetworks = false
  description             = "Main workshop VPC network"
}

resource "google_compute_subnetwork" "subnets" {
  count         = length(var.subnet_cidrs)
  name          = "${var.name_prefix}-subnet-${var.regions[count.index]}"
  ip_cidr_range = var.subnet_cidrs[count.index]
  network       = google_compute_network.vpc.id
  region        = var.regions[count.index]
  
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
  }
}

# DNS resources
resource "google_dns_managed_zone" "private_zone" {
  name        = "${var.name_prefix}-private-zone"
  dns_name    = "workshop.internal."
  description = "Private DNS zone for workshop"
  
  visibility = "private"
  
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}

resource "google_dns_record_set" "records" {
  count        = length(var.dns_records)
  name         = "${var.dns_records[count.index]}.${var.name_prefix}.workshop.internal."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private_zone.name
  rrdatas      = ["10.0.0.${10 + count.index}"]
}

# IAM resources
resource "google_service_account" "service_accounts" {
  count        = length(var.service_accounts)
  account_id   = "${var.name_prefix}-${var.service_accounts[count.index]}"
  display_name = "Workshop ${var.service_accounts[count.index]} service account"
  description  = "Service account for ${var.service_accounts[count.index]} services"
}

resource "google_project_iam_binding" "project_roles" {
  count   = length(var.project_roles)
  project = var.project_id
  role    = var.project_roles[count.index]
  
  members = [
    "serviceAccount:${google_service_account.service_accounts[0].email}",
  ]
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
  default     = [
    "roles/monitoring.viewer",
    "roles/logging.viewer"
  ]
}
