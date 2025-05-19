variable "name_prefix" {
  description = "Prefix for resource names to ensure uniqueness"
  type        = string
}

variable "regions" {
  description = "Regions for subnets"
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "CIDR ranges for subnets"
  type        = list(string)
}
