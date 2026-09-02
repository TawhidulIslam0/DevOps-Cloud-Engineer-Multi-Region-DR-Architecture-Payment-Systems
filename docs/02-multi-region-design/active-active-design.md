# Active-Active Multi-Region Disaster Recovery Architecture

## 1. Executive Summary

This document defines an active-active multi-region architecture for PaySecure Gateway Private Limited using AWS Mumbai (`ap-south-1`) and AWS Hyderabad (`ap-south-2`).

Unlike the active-passive design, both regions actively serve production traffic during normal operation. Traffic is distributed between Mumbai and Hyderabad using latency-based or weighted routing with health checks. If one region fails, the failed region is removed from the traffic pool and the remaining region continues serving production traffic.

The active-active model provides the highest level of regional availability considered in this project. It can reduce recovery time because the secondary region does not need to be started from a cold state. However, the architecture introduces substantially greater complexity in distributed data management.

PaySecure is a payment gateway processing approximately 3.2 million transactions per day and approximately 500 crore INR in daily transaction value. Peak load reaches approximately 1,200 TPS. The system therefore cannot treat regional active-active operation as simply duplicating application servers.

The most important design challenge is transaction consistency.

Both regions must be able to process requests while preventing:

- duplicate payments
- double spending
- conflicting transaction states
- settlement discrepancies
- duplicate webhook deliveries
- inconsistent idempotency records
- Kafka event duplication
- split-brain processing

The target architecture therefore uses active-active compute while applying component-specific data strategies.

DynamoDB Global Tables is appropriate for globally replicated session and idempotency state. Aurora Global Database provides cross-region replication but does not represent a fully multi-writer relational database. Therefore, payment transaction ownership and write routing must be carefully designed.

Kafka uses cross-region replication with strong idempotent consumer behavior. Redis is treated as an acceleration layer and must never become the authoritative payment ledger.

The resulting architecture is more expensive and operationally demanding than active-passive. AWS identifies multi-site active-active as the most operationally complex DR strategy and recommends using it when business requirements justify that complexity.

---

## 2. Existing Architecture

PaySecure currently operates from Mumbai only.

The current application stack contains:

- 24 EKS worker nodes
- three Availability Zones
- approximately 180 pods
- 12 payment microservices
- Aurora PostgreSQL 15.4
- DynamoDB
- ElastiCache Redis
- six-broker MSK
- ALB
- AWS WAF
- Istio with mTLS
- Transit Gateway
- PrivateLink
- KMS
- Secrets Manager
- CloudTrail
- GuardDuty
- Prometheus
- Grafana
- ELK
- PagerDuty
- Jaeger

The current architecture is strong against Availability Zone failure but vulnerable to complete regional failure.

The active-active design removes the single-region dependency by deploying the workload in both Mumbai and Hyderabad.

---

## 3. Regional Architecture

Both regions are complete production environments.

### Mumbai

```text
Internet
   |
Route 53 / Global Traffic Management
   |
Mumbai ALB
   |
WAF
   |
EKS
   |
12 Microservices