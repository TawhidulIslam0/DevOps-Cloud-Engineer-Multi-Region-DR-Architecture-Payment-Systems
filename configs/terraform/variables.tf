variable "primary_region" {
  description = "Primary AWS region for PaySecure production."
  type        = string
  default     = "ap-south-1"
}

variable "dr_region" {
  description = "Secondary AWS region used for disaster recovery."
  type        = string
  default     = "ap-south-2"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dr"
}

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "paysecure"
}

variable "vpc_cidr_primary" {
  description = "CIDR range for the primary-region VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "vpc_cidr_dr" {
  description = "CIDR range for the DR-region VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones_primary" {
  description = "Availability Zones used by the primary region."
  type        = list(string)
  default = [
    "ap-south-1a",
    "ap-south-1b",
    "ap-south-1c"
  ]
}

variable "availability_zones_dr" {
  description = "Availability Zones used by the DR region."
  type        = list(string)
  default = [
    "ap-south-2a",
    "ap-south-2b",
    "ap-south-2c"
  ]
}