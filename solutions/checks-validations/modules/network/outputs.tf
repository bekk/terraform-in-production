output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}
