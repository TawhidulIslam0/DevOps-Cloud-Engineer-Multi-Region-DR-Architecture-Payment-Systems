# Terraform DR Configuration

## Purpose

This directory contains reference Terraform configurations for the PaySecure multi-region disaster recovery architecture.

The configuration represents:

- AWS Mumbai (`ap-south-1`) as the primary region
- AWS Hyderabad (`ap-south-2`) as the DR region
- Multi-AZ VPC networking
- EKS application clusters
- Aurora PostgreSQL
- DynamoDB
- Amazon MSK
- ElastiCache Redis
- S3
- KMS
- Security groups
- IAM
- Cross-region recovery dependencies

## Architecture Model

```text
Mumbai Primary
    |
    +-- VPC
    +-- EKS
    +-- Aurora PostgreSQL
    +-- DynamoDB
    +-- MSK
    +-- Redis
    +-- S3
    |
    | Cross-region replication
    v
Hyderabad DR
    |
    +-- VPC
    +-- EKS
    +-- Aurora PostgreSQL
    +-- DynamoDB
    +-- MSK
    +-- Redis
    +-- S3