# Active-Passive Multi-Region Disaster Recovery Architecture

## 1. Executive Summary

This document defines the proposed active-passive multi-region disaster recovery architecture for PaySecure Gateway Private Limited. The objective is to transform the existing single-region AWS deployment in Mumbai (`ap-south-1`) into a resilient two-region architecture that can continue payment-processing operations during a complete regional failure.

The existing production environment operates entirely in AWS Mumbai. Mumbai provides three Availability Zones and currently hosts the complete application, database, messaging, caching, networking, security, and observability stack. This architecture provides strong protection against individual Availability Zone failures, but a regional outage would affect the complete production environment simultaneously.

The proposed architecture retains Mumbai as the primary production region and introduces Hyderabad (`ap-south-2`) as the disaster recovery region. Mumbai operates as the active region during normal conditions. Hyderabad operates as a warm standby environment containing the required infrastructure, application artifacts, replicated state, security configuration, and operational tooling required to assume production traffic during a Mumbai regional failure.

The target availability objectives are 99.99% availability, Recovery Point Objective (RPO) below one minute, and Recovery Time Objective (RTO) below five minutes. These targets require more than periodic backups. Critical state must be replicated continuously or near-continuously, the recovery environment must already be provisioned, automated health checks must detect regional failure, DNS failover must redirect traffic, and the Hyderabad application tier must be capable of rapidly assuming the production workload.

The active-passive model deliberately keeps transaction writes under controlled ownership. During normal operation, Mumbai is the authoritative production region. Hyderabad receives replicated data and maintains standby infrastructure but does not independently process normal customer transaction traffic. This reduces the possibility of conflicting writes, duplicate transaction processing, settlement inconsistencies, and split-brain behavior.

The architecture uses Amazon Route 53 for DNS failover and health checking, Aurora Global Database for relational database replication, DynamoDB multi-region replication for sessions and idempotency state, cross-region Kafka replication for MSK event streams, Redis replication or rebuild mechanisms for cache state, and cross-region replication of application artifacts and security configuration.

The design prioritizes transaction correctness, controlled recovery, operational simplicity, and regulatory compliance while still providing regional disaster recovery capability.

---

## 2. Existing Architecture and Disaster Recovery Problem

The current PaySecure production environment is deployed entirely in AWS Mumbai (`ap-south-1`).

The application layer consists of an Amazon EKS cluster running Kubernetes 1.28. The cluster contains 24 worker nodes distributed across three Availability Zones and approximately 180 pods supporting 12 microservices:

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

Horizontal Pod Autoscaling uses CPU utilization and transactions-per-second-per-pod metrics to adjust application capacity.

The transactional data layer uses Amazon Aurora PostgreSQL 15.4 with one writer and two reader instances using a Multi-AZ architecture. Aurora stores transaction records, merchant configuration, tokenised card information, and settlement batches.

Amazon DynamoDB stores session management information and idempotency keys. The current configuration uses approximately 10,000 RCU and 5,000 WCU of provisioned capacity.

Amazon ElastiCache for Redis operates in cluster mode and supports merchant configuration caching, rate limiting, and frequently accessed transaction lookups.

Amazon MSK provides Kafka-based event streaming using six brokers. The environment handles approximately 50,000 messages per second during peak periods and retains Kafka topics for seven days. Major topics include Transaction Events, Settlement Triggers, Webhook Deliveries, and Audit Log Ingestion.

External traffic enters through an Application Load Balancer protected by AWS WAF. Internal service-to-service communication uses Istio Service Mesh with mutual TLS. AWS Transit Gateway connects the production environment with corporate infrastructure and partner-bank VPN connections. PrivateLink endpoints provide private connectivity to services including Amazon S3, AWS KMS, and AWS Secrets Manager.

The architecture also contains CloudTrail, GuardDuty, Prometheus, Grafana, OpenSearch/ELK, PagerDuty, Jaeger, and CloudWatch-based monitoring.

The principal weakness is therefore not Availability Zone resilience. The weakness is regional concentration. A complete Mumbai regional outage could simultaneously remove application compute, the primary database writer, regional cache capacity, Kafka brokers, regional networking dependencies, and other production resources.

A multi-region architecture is required to create an independent recovery environment.

---

## 3. Region Selection

### 3.1 Mumbai as the Primary Region

Mumbai (`ap-south-1`) remains the primary region because it is the existing production location.

Keeping Mumbai as primary avoids unnecessary migration risk and preserves the existing production network topology, partner-bank connectivity, security controls, monitoring configuration, operational procedures, and application deployment model.

The existing Mumbai environment already provides three Availability Zones and established production capacity. The objective of this project is regional disaster recovery rather than relocation of the production workload.

Mumbai therefore remains the authoritative region during normal operation.

### 3.2 Hyderabad as the Disaster Recovery Region

Hyderabad (`ap-south-2`) is selected as the disaster recovery region.

Hyderabad provides geographic separation from Mumbai while remaining within India. This is important for PaySecure because payment-related information and operational data may be subject to Indian data-localisation and regulatory requirements.

The proposed Hyderabad environment contains the major AWS building blocks required by the workload, including EKS, Aurora, DynamoDB, ElastiCache, MSK, ECR, Elastic Load Balancing, S3, KMS, Secrets Manager, CloudWatch, and related networking capabilities.

The recovery environment is designed as a warm standby rather than an empty account or backup-only environment. Required infrastructure should already exist so that failover does not depend on provisioning an entire production environment after the disaster has occurred.

### 3.3 Latency Measurement and Region Validation

The architecture should not rely on an assumed Mumbai-to-Hyderabad latency value.

Instead, latency must be measured from the actual production networking environment before final capacity and replication thresholds are established.

The measurement plan should include:

| Measurement | Required Metric |
|---|---|
| Mumbai → Hyderabad network latency | p50, p95, p99 |
| TCP connection establishment | p50, p95, p99 |
| TLS connection establishment | p50, p95, p99 |
| Aurora replication lag | average and maximum |
| Kafka replication lag | messages/time lag |
| DynamoDB replication delay | observed replication metrics |
| Redis replication delay | observed replication metrics |
| Packet loss | percentage |
| Jitter | milliseconds |
| Peak-period performance | p95/p99 during load |

Measurements should be repeated during normal business periods and high-traffic periods.

The final design should use measured values rather than a theoretical latency number. This is particularly important because asynchronous replication performance directly affects the achievable RPO.

---

## 4. Target Active-Passive Topology

The proposed topology consists of two independent AWS regional environments.

### Mumbai — Active Production

Mumbai contains:

- Application Load Balancer
- AWS WAF
- EKS cluster
- 24 worker nodes
- Approximately 180 pods
- 12 PaySecure microservices
- Istio Service Mesh with mTLS
- Aurora PostgreSQL writer and readers
- DynamoDB
- ElastiCache Redis
- Amazon MSK
- Security and compliance controls
- Monitoring and observability services

All normal customer traffic is served by Mumbai.

### Hyderabad — Passive Warm Standby

Hyderabad contains:

- Application Load Balancer
- AWS WAF configuration
- EKS cluster
- Standby application capacity
- Replicated application artifacts
- Aurora Global Database secondary
- DynamoDB replicated state
- Redis standby/replication strategy
- Replicated Kafka topics
- Security configuration
- Monitoring and operational tooling

Hyderabad does not normally serve customer transaction traffic.

During a regional disaster, Hyderabad is promoted to become the production region.

---

## 5. DNS Routing and Health Checks

Amazon Route 53 provides the global DNS failover mechanism.

The architecture uses an active-passive failover policy with a primary endpoint representing the Mumbai production environment and a secondary endpoint representing the Hyderabad recovery environment.

Under normal conditions:

```text
Client
  |
  v
Route 53
  |
  | Primary Healthy
  v
Mumbai ALB
  |
  v
Mumbai EKS

## 6. Data Layer Replication Strategies

### 6.1 Relational Database Replication (Aurora Global Database)

The primary relational data store utilizes Amazon Aurora PostgreSQL 15.4[cite: 2]. To achieve cross-region disaster recovery for transactional records, merchant configurations, tokenised card profiles, and settlement batches, the architecture deploys an **Aurora Global Database** configuration[cite: 1].

* **Primary Writer Region**: Mumbai (`ap-south-1`) acts as the primary instance processing all write transactions and serving local read traffic[cite: 2, 4].
* **Secondary Standby Region**: Hyderabad (`ap-south-2`) hosts the secondary Aurora Global Database cluster[cite: 1]. Replication occurs at the storage layer via dedicated AWS infrastructure rather than database-engine statement replay, reducing replication latency and resource overhead on the database engine.
* **Replication Performance**: Physical storage replication ensures that write operations executed in Mumbai are propagated to Hyderabad with minimal lag. Under normal operating conditions, cross-region storage replication latency stays consistently below one second, satisfying the RPO target of under one minute[cite: 1].
* **Failover Mechanics**: During a regional disaster, the Hyderabad Aurora cluster can be promoted to a standalone primary writer. Planned failovers execute cleanly with zero data loss, while unplanned failovers maintain an RPO bound by the last successfully replicated storage chunk (typically sub-seconds to a few seconds).

### 6.2 NoSQL State Replication (DynamoDB Global Tables)

Session management data and idempotency keys require high throughput and multi-region availability to prevent duplicate transaction submissions during failover scenarios[cite: 2].

* **Global Tables Implementation**: Amazon DynamoDB is configured using Global Tables, replicating session and idempotency tables asynchronously between Mumbai and Hyderabad[cite: 1].
* **Conflict Resolution**: DynamoDB uses a last-writer-wins reconciliation model based on physical timestamps, though the active-passive application design minimizes concurrent writes to the same keys outside of active failover transition periods[cite: 1].
* **Performance Impact**: Global Tables provide local read and write performance in the active region while keeping the standby region fully synchronized, supporting the sub-minute RPO objective[cite: 1].

### 6.3 Caching Layer and Event Streaming (ElastiCache and MSK)

* **Amazon ElastiCache for Redis**: Because cache data represents ephemeral or reproducible state (such as rate limits and merchant configuration lookups), the passive region maintains a separate Redis cluster[cite: 2]. In the event of a failover, microservices initialize or repopulate cache entries directly from Aurora and DynamoDB, or leverage replication streams where applicable.
* **Amazon MSK (Kafka) Cross-Region Replication**: Critical streaming data—including Transaction Events, Settlement Triggers, Webhook Deliveries, and Audit Logs—is replicated asynchronously across regions using MirrorMaker 2 or native MSK replication features[cite: 2]. This ensures event consumer offsets can recover in Hyderabad without dropping event-driven workflows.

---

## 7. Compute Tier and Container Orchestration (Amazon EKS)

### 7.1 Cluster Provisioning and GitOps Synchronization

The application tier runs on Amazon EKS across both regions, managed via automated GitOps pipelines (such as ArgoCD)[cite: 2].

* **Standby Pod Readiness**: While Mumbai runs 24 worker nodes and ~180 pods across 12 microservices (`payment-api`, `transaction-processor`, `settlement-engine`, `fraud-detection`, `notification-service`, `merchant-portal`, `reconciliation-worker`, `audit-logger`, `tokenisation-service`, `webhook-dispatcher`, `rate-limiter`, and `health-monitor`), the Hyderabad EKS cluster maintains a warm standby footprint[cite: 2, 4].
* **Resource Sizing**: To balance cost and availability, the Hyderabad EKS cluster maintains a scaled-down worker node pool (e.g., 30% to 50% of peak production capacity) with Horizontal Pod Autoscalers (HPA) pre-configured to rapidly scale up upon receiving traffic or metric triggers during a failover event.
* **Artifact Synchronization**: Container images are continuously synced to Amazon Elastic Container Registry (ECR) repositories in Hyderabad, ensuring that deployment manifests can be applied instantly without relying on cross-region image pulls during an emergency.

---

## 8. Disaster Recovery Execution and Failover Runbook

### 8.1 Detection Phase

* Automated health monitoring via Route 53 health checks and CloudWatch composite alarms continuously evaluate error rates, latency spikes, and infrastructure reachability in Mumbai[cite: 1, 5].
* If criteria indicating a catastrophic regional outage are met, an automated or operator-confirmed trigger initiates the failover sequence.

### 8.2 Promotion and Traffic Rerouting Phase

1. **Database Promotion**: Promote the Aurora Global Database cluster in Hyderabad (`ap-south-2`) to primary writer status[cite: 1, 4].
2. **Compute Scaling**: Execute the EKS scaling script or trigger automated HPA scaling policies in Hyderabad to expand worker nodes and pod replicas to full production capacity[cite: 2, 4].
3. **DNS Cutover**: Route 53 health check failures automatically (or via manual operator override) switch the global DNS records from the Mumbai Application Load Balancer to the Hyderabad Application Load Balancer[cite: 1, 5].
4. **Validation**: Run synthetic end-to-end payment transactions against the Hyderabad endpoint to verify tokenization, database writes, and event dispatching integrity before declaring the incident resolved[cite: 1].

---

## 9. Compliance, Security, and Governance

* **Data Localization**: Maintaining both primary and disaster recovery regions within India (`ap-south-1` and `ap-south-2`) ensures strict adherence to national data localization mandates and regulatory frameworks governing payment transaction processing[cite: 1, 3].
* **Security Controls**: AWS WAF rules, IAM cross-account roles, KMS customer-managed keys, and Secrets Manager secrets are mirrored across both regions to maintain identical security postures in active and passive states[cite: 1, 4].