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
