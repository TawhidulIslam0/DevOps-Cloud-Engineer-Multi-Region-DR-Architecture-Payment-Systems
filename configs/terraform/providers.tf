provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = "PaySecure-Multi-Region-DR"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Disaster-Recovery"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project     = "PaySecure-Multi-Region-DR"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Disaster-Recovery"
    }
  }
}