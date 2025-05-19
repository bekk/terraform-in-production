variable "name" {
  description = "The name of the DNS record."
  type        = string
}

variable "zone_name" {
  description = "The name of the DNS zone."
  type        = string
}

variable "ipv4_address" {
  description = "The IPv4 address for the A record."
  type        = string
}


check "private_zone" {
  data "google_dns_managed_zone" "private_zone" {
    name = var.zone_name
  }

  assert {
    condition     = data.google_dns_managed_zone.private_zone.visibility == "private"
    error_message = "The managed zone must be private."
  }
}

resource "google_dns_record_set" "record" {
  name         = var.name
  type         = "A"
  ttl          = 300
  managed_zone = var.zone_name
  rrdatas      = [var.ipv4_address]
}
