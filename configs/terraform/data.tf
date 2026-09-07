# =========================================================
# Aurora PostgreSQL - Primary Region
# =========================================================

resource "aws_rds_global_cluster" "paysecure" {
  global_cluster_identifier = "${var.project_name}-global"

  engine         = "aurora-postgresql"
  engine_version = "15.4"

  database_name = "paysecure"

  storage_encrypted = true
}

resource "aws_rds_cluster" "primary" {
  cluster_identifier = "${var.project_name}-primary"

  engine         = "aurora-postgresql"
  engine_version = "15.4"

  global_cluster_identifier = aws_rds_global_cluster.paysecure.id

  database_name   = "paysecure"
  master_username = "paysecure_admin"

  manage_master_user_password = true

  db_subnet_group_name = module.primary_vpc.database_subnet_group_name

  storage_encrypted = true

  backup_retention_period = 7

  preferred_backup_window      = "18:00-19:00"
  preferred_maintenance_window = "sun:19:00-sun:20:00"

  deletion_protection = true

  skip_final_snapshot = true

  tags = {
    RegionRole = "Primary"
    DataClass  = "Financial"
  }
}

resource "aws_rds_cluster_instance" "primary" {
  count = 3

  identifier = "${var.project_name}-primary-${count.index + 1}"

  cluster_identifier = aws_rds_cluster.primary.id

  instance_class = "db.r6g.2xlarge"

  engine         = aws_rds_cluster.primary.engine
  engine_version = aws_rds_cluster.primary.engine_version

  publicly_accessible = false

  tags = {
    RegionRole = "Primary"
  }
}

# =========================================================
# Aurora PostgreSQL - DR Region
# =========================================================

resource "aws_rds_cluster" "dr" {
  provider = aws.dr

  cluster_identifier = "${var.project_name}-dr"

  engine         = "aurora-postgresql"
  engine_version = "15.4"

  global_cluster_identifier = aws_rds_global_cluster.paysecure.id

  db_subnet_group_name = module.dr_vpc.database_subnet_group_name

  storage_encrypted = true

  backup_retention_period = 7

  deletion_protection = true

  skip_final_snapshot = true

  tags = {
    RegionRole = "DR"
    DataClass  = "Financial"
  }
}

resource "aws_rds_cluster_instance" "dr" {
  provider = aws.dr

  count = 2

  identifier = "${var.project_name}-dr-${count.index + 1}"

  cluster_identifier = aws_rds_cluster.dr.id

  instance_class = "db.r6g.2xlarge"

  engine         = aws_rds_cluster.dr.engine
  engine_version = aws_rds_cluster.dr.engine_version

  publicly_accessible = false

  tags = {
    RegionRole = "DR"
  }
}

# =========================================================
# DynamoDB Global Table
# =========================================================

resource "aws_dynamodb_table" "sessions" {
  name         = "${var.project_name}-sessions"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  global_secondary_index {
    name            = "merchant-index"
    hash_key        = "merchant_id"
    projection_type = "ALL"
  }

  attribute {
    name = "merchant_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  replica {
    region_name = var.dr_region
  }

  tags = {
    RegionRole = "Primary"
    DataClass  = "Session-Idempotency"
  }
}

# =========================================================
# DynamoDB Idempotency Table
# =========================================================

resource "aws_dynamodb_table" "idempotency" {
  name         = "${var.project_name}-idempotency"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "idempotency_key"

  attribute {
    name = "idempotency_key"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  replica {
    region_name = var.dr_region
  }

  tags = {
    RegionRole = "Primary"
    DataClass  = "Transaction-Control"
  }
}