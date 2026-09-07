# =========================================================
# Primary EKS Cluster - Mumbai
# =========================================================

module "primary_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project_name}-primary"
  kubernetes_version = "1.28"

  region = var.primary_region

  vpc_id     = module.primary_vpc.vpc_id
  subnet_ids = module.primary_vpc.private_subnets

  endpoint_private_access = true
  endpoint_public_access  = true

  enable_irsa = true

  addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    application = {
      name = "${var.project_name}-primary-workers"

      instance_types = ["m6i.2xlarge"]

      min_size     = 24
      max_size     = 36
      desired_size = 24

      capacity_type = "ON_DEMAND"

      subnet_ids = module.primary_vpc.private_subnets

      labels = {
        workload = "application"
        region   = "primary"
      }

      tags = {
        RegionRole = "Primary"
      }
    }
  }

  tags = {
    RegionRole = "Primary"
    Region     = var.primary_region
  }
}

# =========================================================
# DR EKS Cluster - Hyderabad
# =========================================================

module "dr_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  providers = {
    aws = aws.dr
  }

  name               = "${var.project_name}-dr"
  kubernetes_version = "1.28"

  region = var.dr_region

  vpc_id     = module.dr_vpc.vpc_id
  subnet_ids = module.dr_vpc.private_subnets

  endpoint_private_access = true
  endpoint_public_access  = true

  enable_irsa = true

  addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    application = {
      name = "${var.project_name}-dr-workers"

      instance_types = ["m6i.2xlarge"]

      # DR environment starts smaller and scales during failover.
      min_size     = 6
      max_size     = 24
      desired_size = 8

      capacity_type = "ON_DEMAND"

      subnet_ids = module.dr_vpc.private_subnets

      labels = {
        workload = "application"
        region   = "dr"
      }

      tags = {
        RegionRole = "DR"
      }
    }
  }

  tags = {
    RegionRole = "DR"
    Region     = var.dr_region
  }
}