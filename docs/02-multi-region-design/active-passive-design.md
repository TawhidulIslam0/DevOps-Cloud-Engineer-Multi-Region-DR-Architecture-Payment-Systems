# Active-Passive Multi-Region Disaster Recovery Architecture

## 1. Executive Summary

This document defines the proposed active-passive multi-region disaster recovery architecture for PaySecure Gateway Private Limited. The objective is to transform the existing single-region AWS architecture in Mumbai (`ap-south-1`) into a resilient two-region deployment using AWS Mumbai as the primary production region and AWS Hyderabad (`ap-south-2`) as the disaster recovery region.

PaySecure currently processes approximately 3.2 million transactions per day, representing approximately 500 crore INR in daily transaction value, across approximately 45,000 merchants. The platform experiences approximately 1,200 transactions per second during peak festival periods and currently operates entirely within the Mumbai AWS Region. The current architecture provides strong Availability Zone-level resilience but does not protect the platform from a complete regional outage.

The target state must achieve 99.99% availability with an RPO below one minute and an RTO below five minutes. These targets are intentionally more stringent than the regulatory baseline identified in the project brief and are necessary because payment processing requires continuity, transaction integrity, and controlled recovery during regional failures.

The active-passive strategy designates Mumbai as the active production region and Hyderabad as the recovery region. Mumbai handles normal production traffic. Hyderabad maintains a continuously synchronized or near-continuously synchronized copy of required state and a warm standby application environment. If Mumbai becomes unavailable, automated health checks identify the failure and Route 53 changes traffic routing to Hyderabad. The Hyderabad application stack is then promoted or scaled to full production capacity.

The strategy prioritizes operational simplicity, controlled transaction ownership, and predictable failover behavior over the maximum theoretical availability of active-active architecture. This is particularly important for a payment gateway because uncontrolled concurrent writes across regions can introduce duplicate processing, transaction conflicts, settlement inconsistencies, and split-brain conditions.

---

## 2. Existing Architecture and Problem Statement

The current PaySecure production architecture is deployed exclusively in AWS Mumbai (`ap-south-1`).

The application layer consists of an Amazon EKS cluster with 24 worker nodes distributed across three Availability Zones. Approximately 180 Kubernetes pods run across 12 microservices:

1. `payment-api`
2. `transaction-processor`
3. `settlement-engine`
4. `fraud-detection`
5. `notification-service`
6. `merchant-portal`
7. `reconciliation-worker`
8. `audit-logger`
9. `tokenisation-service`
10. `webhook-dispatcher`
11. `rate-limiter`
12. `health-monitor`

Horizontal Pod Autoscaling uses CPU utilization and transactions-per-second-per-pod metrics.

The primary transactional database is Amazon Aurora PostgreSQL 15.4 using one writer and two reader replicas with a Multi-AZ deployment. Aurora stores transaction records, merchant configuration, tokenised card data, and settlement batches.

DynamoDB handles session management and idempotency keys using provisioned capacity of 10,000 RCU and 5,000 WCU. ElastiCache Redis operates in cluster mode and supports merchant configuration caching, rate limiting, and frequently accessed transaction lookups.

Amazon MSK provides event streaming through a six-broker Kafka cluster. The cluster handles transaction events, settlement triggers, webhook deliveries, and audit-log ingestion and processes approximately 50,000 messages per second during peak periods with seven-day topic retention.

External traffic enters through an Application Load Balancer protected by AWS WAF. Inter-service communication uses Istio with mTLS. Transit Gateway connects the production environment to corporate infrastructure and partner-bank VPNs. PrivateLink provides private connectivity to AWS services such as S3, KMS, and Secrets Manager.

The architecture is currently resilient to individual component and Availability Zone failures, but a complete Mumbai regional outage would simultaneously affect the application tier, database, cache, streaming platform, networking dependencies, and regional service endpoints.

The primary architectural problem is therefore not component-level availability but regional concentration of failure.

---

## 3. Region Selection

### 3.1 Primary Region

Mumbai (`ap-south-1`) remains the primary production region because the existing PaySecure workload is already deployed there. Moving production to another region would introduce unnecessary migration risk while the immediate objective is regional disaster recovery.

Mumbai also provides the established network connectivity, partner-bank connectivity, production configuration, operational knowledge, and existing monitoring integrations required by the business.

### 3.2 Recovery Region

Hyderabad (`ap-south-2`) is selected as the recovery region.

The project brief specifically requires evaluation of Hyderabad as the secondary Indian AWS region. Keeping both production and recovery environments within India supports the project's data-localisation requirement and avoids designing a DR architecture that depends on storing payment data outside India.

Hyderabad provides the required AWS regional building blocks for the proposed architecture, including EKS, Aurora, DynamoDB, ElastiCache, MSK, ECR, load balancing, CloudWatch, KMS, Secrets Manager, S3, and related networking services.

The two regions are geographically separated while remaining within the Indian regulatory and data-localisation boundary.

### 3.3 Latency Consideration

The architecture should not claim a specific Mumbai-to-Hyderabad latency figure until it is measured from the actual production network environment.

A formal latency baseline should therefore be established during implementation using repeated measurements over multiple periods:

- Mumbai-to-Hyderabad TCP latency
- Mumbai-to-Hyderabad TLS connection latency
- Database replication latency
- Kafka replication latency
- Redis replication latency
- Packet loss
- Jitter
- Peak-period behavior

The final production design should use measured p50, p95, and p99 values rather than a single theoretical latency value.

---

## 4. Target Active-Passive Architecture

The target topology consists of two complete regional environments.

### Mumbai

```text
Users / Merchants
       |
   Route 53
       |
       v
Application Load Balancer
       |
      WAF
       |
     EKS
       |
  PaySecure Services
       |
+------+-------+--------+--------+
|              |        |        |
Aurora       DynamoDB  Redis     MSK