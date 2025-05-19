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
