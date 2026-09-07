locals {
  primary_private_subnets = {
    "ap-south-1a" = "10.10.1.0/24"
    "ap-south-1b" = "10.10.2.0/24"
    "ap-south-1c" = "10.10.3.0/24"
  }

  primary_public_subnets = {
    "ap-south-1a" = "10.10.11.0/24"
    "ap-south-1b" = "10.10.12.0/24"
    "ap-south-1c" = "10.10.13.0/24"
  }

  dr_private_subnets = {
    "ap-south-2a" = "10.20.1.0/24"
    "ap-south-2b" = "10.20.2.0/24"
    "ap-south-2c" = "10.20.3.0/24"
  }

  dr_public_subnets = {
    "ap-south-2a" = "10.20.11.0/24"
    "ap-south-2b" = "10.20.12.0/24"
    "ap-south-2c" = "10.20.13.0/24"
  }
}

# ---------------------------------------------------------
# Primary Region VPC
# ---------------------------------------------------------

module "primary_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project_name}-primary-vpc"
  cidr = var.vpc_cidr_primary

  azs = var.availability_zones_primary

  private_subnets = [
    for az in var.availability_zones_primary :
    local.primary_private_subnets[az]
  ]

  public_subnets = [
    for az in var.availability_zones_primary :
    local.primary_public_subnets[az]
  ]

  enable_nat_gateway = true
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    RegionRole = "Primary"
    Region     = var.primary_region
  }
}

# ---------------------------------------------------------
# DR Region VPC
# ---------------------------------------------------------

module "dr_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  providers = {
    aws = aws.dr
  }

  name = "${var.project_name}-dr-vpc"
  cidr = var.vpc_cidr_dr

  azs = var.availability_zones_dr

  private_subnets = [
    for az in var.availability_zones_dr :
    local.dr_private_subnets[az]
  ]

  public_subnets = [
    for az in var.availability_zones_dr :
    local.dr_public_subnets[az]
  ]

  enable_nat_gateway = true
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    RegionRole = "DR"
    Region     = var.dr_region
  }
}