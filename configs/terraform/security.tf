resource "aws_kms_key" "paysecure" {
  description             = "PaySecure primary-region encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    RegionRole = "Primary"
  }
}

resource "aws_kms_alias" "paysecure" {
  name          = "alias/${var.project_name}-primary"
  target_key_id = aws_kms_key.paysecure.key_id
}

resource "aws_kms_key" "paysecure_dr" {
  provider = aws.dr

  description             = "PaySecure DR-region encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    RegionRole = "DR"
  }
}

resource "aws_kms_alias" "paysecure_dr" {
  provider = aws.dr

  name          = "alias/${var.project_name}-dr"
  target_key_id = aws_kms_key.paysecure_dr.key_id
}

resource "aws_security_group" "msk_primary" {
  name        = "${var.project_name}-msk-primary"
  description = "MSK access from PaySecure application workloads"
  vpc_id      = module.primary_vpc.vpc_id

  ingress {
    description = "Kafka TLS"
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_primary]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "msk_dr" {
  provider = aws.dr

  name        = "${var.project_name}-msk-dr"
  description = "MSK DR access from PaySecure application workloads"
  vpc_id      = module.dr_vpc.vpc_id

  ingress {
    description = "Kafka TLS"
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_dr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis_primary" {
  name        = "${var.project_name}-redis-primary"
  description = "Redis access from PaySecure application workloads"
  vpc_id      = module.primary_vpc.vpc_id

  ingress {
    description = "Redis TLS"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_primary]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis_dr" {
  provider = aws.dr

  name        = "${var.project_name}-redis-dr"
  description = "Redis DR access from PaySecure application workloads"
  vpc_id      = module.dr_vpc.vpc_id

  ingress {
    description = "Redis TLS"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_dr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "primary" {
  name       = "${var.project_name}-redis-primary"
  subnet_ids = module.primary_vpc.private_subnets
}

resource "aws_elasticache_subnet_group" "dr" {
  provider = aws.dr

  name       = "${var.project_name}-redis-dr"
  subnet_ids = module.dr_vpc.private_subnets
}