# =========================================================
# Amazon MSK - Primary Region
# =========================================================

resource "aws_msk_cluster" "primary" {
  cluster_name           = "${var.project_name}-primary"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = 6

  broker_node_group_info {
    instance_type   = "kafka.m7g.large"
    client_subnets  = module.primary_vpc.private_subnets
    security_groups = [aws_security_group.msk_primary.id]

    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.paysecure.arn

    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  enhanced_monitoring = "PER_BROKER"

  tags = {
    RegionRole = "Primary"
    DataClass  = "Financial-Events"
  }
}

# =========================================================
# Amazon MSK - DR Region
# =========================================================

resource "aws_msk_cluster" "dr" {
  provider = aws.dr

  cluster_name           = "${var.project_name}-dr"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.m7g.large"
    client_subnets  = module.dr_vpc.private_subnets
    security_groups = [aws_security_group.msk_dr.id]

    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.paysecure_dr.arn

    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  enhanced_monitoring = "PER_BROKER"

  tags = {
    RegionRole = "DR"
    DataClass  = "Financial-Events"
  }
}

# =========================================================
# ElastiCache Redis - Primary Region
# =========================================================

resource "aws_elasticache_replication_group" "primary" {
  replication_group_id = "${var.project_name}-primary"
  description          = "PaySecure primary Redis cluster"

  engine             = "redis"
  node_type          = "cache.r6g.large"
  num_cache_clusters = 3

  port = 6379

  subnet_group_name  = aws_elasticache_subnet_group.primary.name
  security_group_ids = [aws_security_group.redis_primary.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  automatic_failover_enabled = true
  multi_az_enabled           = true

  snapshot_retention_limit = 7

  tags = {
    RegionRole = "Primary"
    DataClass  = "Merchant-Configuration"
  }
}

# =========================================================
# ElastiCache Redis - DR Region
# =========================================================

resource "aws_elasticache_replication_group" "dr" {
  provider = aws.dr

  replication_group_id = "${var.project_name}-dr"
  description          = "PaySecure DR Redis cluster"

  engine             = "redis"
  node_type          = "cache.r6g.large"
  num_cache_clusters = 2

  port = 6379

  subnet_group_name  = aws_elasticache_subnet_group.dr.name
  security_group_ids = [aws_security_group.redis_dr.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  automatic_failover_enabled = true
  multi_az_enabled           = true

  snapshot_retention_limit = 7

  tags = {
    RegionRole = "DR"
    DataClass  = "Merchant-Configuration"
  }
}

# =========================================================
# S3 - Primary Bucket
# =========================================================

resource "aws_s3_bucket" "primary" {
  bucket = "${var.project_name}-primary-data"

  tags = {
    RegionRole = "Primary"
    DataClass  = "Application-Data"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.paysecure.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# =========================================================
# S3 - DR Bucket
# =========================================================

resource "aws_s3_bucket" "dr" {
  provider = aws.dr

  bucket = "${var.project_name}-dr-data"

  tags = {
    RegionRole = "DR"
    DataClass  = "Application-Data"
  }
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr" {
  provider = aws.dr

  bucket = aws_s3_bucket.dr.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.paysecure_dr.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# =========================================================
# S3 Cross-Region Replication
# =========================================================

resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  bucket = aws_s3_bucket.primary.id
  role   = aws_iam_role.s3_replication.arn

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.dr
  ]
}