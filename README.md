# PaySecure Multi-Region Disaster Recovery Architecture

## Project Overview

This repository contains the disaster recovery (DR) architecture, operational runbooks, infrastructure configuration, monitoring configuration, cost analysis, data sovereignty analysis, and DR drill documentation for the PaySecure payment platform.

The existing PaySecure platform operates primarily in AWS Mumbai (`ap-south-1`). The DR architecture introduces AWS Hyderabad (`ap-south-2`) as the secondary region and evaluates active-passive and active-active approaches.

The design is intended to improve regional resilience while maintaining payment data integrity, security, compliance, and operational recoverability.

---

## Business and Recovery Objectives

| Objective | Target |
|---|---|
| Availability | 99.99% |
| Recovery Time Objective (RTO) | < 5 minutes |
| Recovery Point Objective (RPO) | < 1 minute |
| Primary Region | Mumbai (`ap-south-1`) |
| DR Region | Hyderabad (`ap-south-2`) |
| Primary DR Strategy | Multi-region |
| Data Protection | Encryption at rest and in transit |
| Compliance Focus | PCI DSS, data sovereignty, auditability |

The RTO and RPO targets are architectural objectives for the proposed DR solution and must be validated through controlled DR exercises.

---

## Current Architecture

The current platform is a single-region AWS deployment in Mumbai.

### Core Components

- Amazon EKS
- 24 worker nodes
- Approximately 180 pods
- 12 microservices
- Application Load Balancer
- AWS WAF
- Aurora PostgreSQL 15.4
- DynamoDB
- ElastiCache for Redis
- Amazon MSK
- Amazon S3
- AWS KMS
- AWS Secrets Manager
- AWS Transit Gateway
- PrivateLink
- CloudTrail
- GuardDuty
- Prometheus
- Grafana
- ELK
- PagerDuty
- Jaeger

### Current Resilience Limitation

The current architecture provides strong Availability Zone resilience inside Mumbai but does not provide automated regional failover.

A Mumbai regional outage could therefore affect:

- Application workloads
- Database availability
- Kafka workloads
- Redis workloads
- Regional networking
- Regional service endpoints
- Payment processing

The proposed architecture addresses this regional failure mode.

---

## Target Multi-Region Architecture

The proposed architecture uses:

**Primary Region**

```text
AWS Mumbai
ap-south-1
```

## Risk Analysis

The 20-mode disaster recovery FMEA, including severity, occurrence, detection, RPN calculations, and mitigation priorities, is documented in [docs/09-risk-analysis/fmea.md](docs/09-risk-analysis/fmea.md).

## Monitoring and Dashboards

Synthetic payment, DNS, cross-region connectivity, certificate, backup-restore, and audience-specific dashboard requirements are documented in [docs/10-monitoring/synthetic-monitoring-and-dashboards.md](docs/10-monitoring/synthetic-monitoring-and-dashboards.md).

## Validation Evidence

Local Terraform, Kubernetes, PowerShell, JSON, FMEA, and failover dry-run results are recorded in [VALIDATION.md](VALIDATION.md). Live AWS testing is intentionally excluded because no sandbox account was available.

## Error Hunter Analysis

Five deliberate architecture inconsistencies and their corrections are documented in [docs/11-error-hunt/deliberate-errors.md](docs/11-error-hunt/deliberate-errors.md).

