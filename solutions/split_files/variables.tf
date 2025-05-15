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
