output "primary_vpc_id" {
  description = "Primary Mumbai VPC ID."
  value       = module.primary_vpc.vpc_id
}

output "dr_vpc_id" {
  description = "DR Hyderabad VPC ID."
  value       = module.dr_vpc.vpc_id
}

output "primary_eks_cluster_name" {
  description = "Primary EKS cluster name."
  value       = module.primary_eks.cluster_name
}

output "dr_eks_cluster_name" {
  description = "DR EKS cluster name."
  value       = module.dr_eks.cluster_name
}

output "primary_aurora_endpoint" {
  description = "Primary Aurora cluster endpoint."
  value       = aws_rds_cluster.primary.endpoint
}

output "dr_aurora_endpoint" {
  description = "DR Aurora cluster endpoint."
  value       = aws_rds_cluster.dr.endpoint
}

output "primary_s3_bucket" {
  description = "Primary S3 bucket."
  value       = aws_s3_bucket.primary.bucket
}

output "dr_s3_bucket" {
  description = "DR S3 bucket."
  value       = aws_s3_bucket.dr.bucket
}