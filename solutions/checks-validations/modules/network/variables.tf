variable "name_prefix" {
  description = "Prefix for resource names to ensure uniqueness"
  type        = string
}

variable "subnets" {
  description = "CIDR ranges for subnets"
  type        = object({
    regions = list(string)
    cidrs   = list(string)
  })

  validation {
    condition     = alltrue([for cidr in var.subnets.cidrs : can(cidrhost(cidr, 255))])
    error_message = "At least one of the specified subnets were too small, or one of the CIDR range was invalid. The subnets needs to contain at least 256 IP addresses (/24 or larger)."
  }
}
