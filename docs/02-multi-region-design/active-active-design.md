# Active-Active Multi-Region Disaster Recovery Architecture

## 1. Executive Summary and Strategic Context

PaySecure Gateway Private Limited operates a mission-critical financial transaction processing infrastructure that handles approximately 3.2 million transactions per day, with a daily transaction volume valued at approximately 500 crore INR. Under peak operational conditions, the platform reaches a throughput of approximately 1,200 transactions per second (TPS). Maintaining uninterrupted service availability, strict financial data integrity, and ultra-low latency is paramount to satisfying regulatory mandates set by the Reserve Bank of India (RBI) and fulfilling strict commercial service-level agreements (SLAs) with partner banking institutions and corporate merchants.

Historically, PaySecure relied on a single-region deployment footprint anchored exclusively in the AWS Mumbai (`ap-south-1`) region. While this single-region topology was carefully structured across three Availability Zones (AZs) with robust internal redundancy, it exposed the core payment infrastructure to catastrophic regional outage risks. Such risks include widespread fiber cuts, regional power grid failures, major cloud provider control-plane outages, or localized natural disasters. 

To bridge this availability gap, PaySecure engineering evaluated two primary multi-region topologies: an Active-Passive (Disaster Recovery) model and an Active-Active (Multi-Region / Multi-Master) model. While an Active-Passive approach provides a straightforward warm-standby framework in AWS Hyderabad (`ap-south-2`) with an RTO of under 15 minutes and an RPO under 5 minutes, it leaves secondary computational resources idle during normal operation and incurs unacceptable failover recovery windows for real-time payment authorization flows.

Consequently, PaySecure has mandated the implementation of a full-scale **Active-Active Multi-Region Architecture** across AWS Mumbai (`ap-south-1`) and AWS Hyderabad (`ap-south-2`). In this operational paradigm, both regions actively serve production traffic concurrently. Traffic is intelligently distributed using Amazon Route 53 latency-based routing coupled with AWS Global Accelerator Anycast IPs. 

However, achieving true active-active execution for a financial payment gateway introduces profound engineering challenges. Unlike stateless web applications, a payment gateway cannot simply duplicate application servers across regions without solving distributed data consistency, write conflict resolution, transaction ordering, idempotency synchronization, and cross-region event streaming. This design document provides the exhaustive blueprint, component-level analysis, data replication strategies, and comparative evaluations necessary to execute this multi-region transformation safely.

---

## 2. Existing Single-Region Infrastructure and Baseline Topology

Before evaluating the transition to an active-active model, it is essential to examine PaySecure's existing operational footprint in AWS Mumbai (`ap-south-1`). The current architecture is engineered for high availability within a single geographical zone, encompassing the following core technology stack:

* **Compute Layer:** An Amazon EKS (Elastic Kubernetes Service) cluster running Kubernetes version 1.28, powered by 24 high-performance worker nodes distributed uniformly across three Availability Zones (`ap-south-1a`, `ap-south-1b`, `ap-south-1c`). The cluster hosts approximately 180 active pods executing 12 core payment microservices.
* **Core Microservices Portfolio:** 
  * `payment-api`: Ingestion engine handling incoming authorization requests.
  * `transaction-processer`: Core workflow coordinator executing payment logic.
  * `settlement-engine`: Batch and real-time ledger settlement processing.
  * `fraud-detection`: Real-time machine learning inference for risk scoring.
  * `notification-service`: Dispatches SMS, email, and push alerts to end users.
  * `merchant-portal`: Backend service supporting merchant dashboards.
  * `reconciliation-worker`: Background reconciliation against banking partners.
  * `audit-logger`: Immutable compliance and security event logging.
  * `tokenisation-service`: Secure cardholder data tokenization (PCI CDE boundary).
  * `webhook-dispatcher`: Outbound event delivery to merchant endpoints.
  * `rate-limiter`: API throttling and traffic shaping engine.
  * `health-monitor`: Internal component health aggregation and reporting.
* **Data and Storage Layer:** 
  * **Amazon Aurora PostgreSQL 15.4:** Multi-AZ relational database cluster (`db.r6g.2xlarge` primary writer instance with dedicated read replicas) housing transactional ledgers and merchant records.
  * **Amazon DynamoDB:** NoSQL data store handling high-velocity session management, rate-limit counters, and critical transaction idempotency keys.
  * **Amazon ElastiCache Redis Cluster:** In-memory cluster mode-enabled datastore used for low-latency transient caching, merchant configurations, and session tokens.
  * **Amazon MSK (Kafka):** A 6-broker managed streaming cluster processing roughly 50,000 messages per second with a 7-day retention policy, driving event-driven asynchronous workflows.
* **Networking & Security:** Application Load Balancer (ALB) fronted by AWS WAF, Istio Service Mesh enforcing mutual TLS (mTLS) for all service-to-service communication, AWS Transit Gateway, AWS PrivateLink endpoints, and strict network segmentation isolating the PCI DSS Cardholder Data Environment (CDE).
* **Observability & Governance:** AWS KMS for cryptographic envelope encryption, AWS Secrets Manager for automated credential rotation, AWS CloudTrail, Amazon GuardDuty, AWS Security Hub, Prometheus, Grafana, ELK Stack for log aggregation, PagerDuty for incident management, and Jaeger for distributed tracing.

While this baseline is exceptionally resilient against single-node or single-AZ failures, it presents a single point of failure at the regional level. The active-active initiative removes this vulnerability by deploying an identical, fully operational production stack in Hyderabad (`ap-south-2`).

---

## 3. Regional Architecture and Dual-Site Topology

Deploying an active-active architecture requires replicating the complete infrastructure stack across both Mumbai (`ap-south-1`) and Hyderabad (`ap-south-2`). Both regions operate as independent, fully functional production datacenters capable of sustaining the entire workload independently during a localized or regional disruption.

### 3.1 Mumbai Primary Region (`ap-south-1`)
The Mumbai deployment serves as the primary operational anchor for southern and western Indian traffic streams.
* **VPC CIDR Structure:** `10.0.0.0/16` partitioned into three private subnets across three AZs (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`).
* **Compute & Service Mesh:** EKS cluster running 24 worker nodes (~180 pods) managed via Istio service mesh, enforcing strict mTLS authorization policies between all 12 microservices.
* **Data Tier:** Houses the primary write-capable Amazon Aurora PostgreSQL cluster, active DynamoDB Global Table replicas, ElastiCache Redis nodes, and a 6-broker Amazon MSK Kafka cluster.

### 3.2 Hyderabad Secondary Region (`ap-south-2`)
The Hyderabad deployment mirrors Mumbai down to the configuration level, serving traffic originating closer to central and northern peninsular zones while acting as a concurrent active master.
* **VPC CIDR Structure:** `10.1.0.0/16` partitioned identically across three AZs (`10.1.1.0/24`, `10.1.2.0/24`, `10.1.3.0/24`) to prevent routing overlaps during cross-region peering or transit gateway attachments.
* **Compute & Service Mesh:** A fully provisioned EKS cluster mirroring Mumbai's node count, pod density, and Istio mTLS security postures.
* **Data Tier:** Synchronized stateful layers including Aurora Global Database read-write target setups, DynamoDB multi-master global tables, Redis Global Datastore nodes, and an active Amazon MSK Kafka cluster synchronized via MirrorMaker 2.

---

## 4. Global Traffic Routing and Edge Acceleration

Routing 50,000 messages per second and up to 1,200 TPS across two active regions requires a sophisticated, low-latency traffic steering mechanism. PaySecure implements a dual-layer routing strategy utilizing **Amazon Route 53** and **AWS Global Accelerator**.

### 4.1 Amazon Route 53 Global DNS with Latency-Based Routing
Amazon Route 53 is configured with latency-based routing policies mapped to the DNS records of the PaySecure payment endpoints. 
* **Health Check Probes:** Route 53 maintains continuous HTTP/HTTPS health check probes against the Application Load Balancers (ALBs) in both Mumbai and Hyderabad at 10-second intervals.
* **Automated Traffic Rerouting:** If an ALB in either region experiences high error rates, hardware degradation, or unresponsiveness, Route 53 automatically deregisters that region's endpoint from its DNS response pool within seconds, seamlessly shifting 100% of traffic to the remaining healthy regional endpoint.

### 4.2 AWS Global Accelerator Integration
To bypass unpredictable public internet routing tables and BGP propagation delays, PaySecure integrates **AWS Global Accelerator**:
* **Anycast IP Addresses:** Global Accelerator provides two static Anycast IP addresses that act as fixed entry points anchored to AWS's global edge network locations.
* **Edge Termination:** Client TCP connections are accepted at the nearest AWS edge location globally. Traffic is then encapsulated and routed over the private, high-speed AWS global network backbone directly into the VPC ingress controllers in Mumbai or Hyderabad. This reduces handshake latency and stabilizes connection pooling for high-frequency merchant API clients.

---

## 5. Stateful Data Replication & Distributed Consistency Strategy

The defining engineering hurdle of an active-active financial architecture is maintaining data consistency across distributed datacenters without introducing locking bottlenecks or split-brain corruption. Because payment gateways require absolute financial accuracy, different storage engines demand tailored replication and consistency models.

### 5.1 Amazon Aurora PostgreSQL 15.4 (Ledger and Relational State)
* **Replication Architecture:** Configured as an Aurora Global Database. The primary write cluster resides in Mumbai (`ap-south-1`), while the Hyderabad cluster (`ap-south-2`) operates as a low-latency secondary region with dedicated reader instances.
* **Write Routing Strategy:** Because standard PostgreSQL relational engines cannot support multi-region multi-master synchronous writes without incurring severe write locks or cascading aborts, write operations for ledger settlements and core financial accounts are pinned to Mumbai during normal operations, with cross-region asynchronous replication propagating changes to Hyderabad in under 1 second. In the event of a primary region evacuation, the Hyderabad cluster can be promoted to primary write status within seconds.
* **Consistency Safeguards:** Application microservices use explicit transaction isolation levels (`SERIALIZABLE` or `READ COMMITTED` with strict version checks) to prevent race conditions during fund transfers.

### 5.2 Amazon DynamoDB Global Tables (Idempotency and Session State)
* **Multi-Master Active-Active Setup:** DynamoDB Global Tables provide fully replicated, multi-master NoSQL storage across both Mumbai and Hyderabad.
* **Idempotency Key Enforcement:** Payment requests include unique merchant-supplied idempotency keys stored in DynamoDB. Because Global Tables synchronize item updates across regions within milliseconds, if a client retry hits Hyderabad instead of Mumbai, the idempotency check instantly catches the duplicate key and rejects or replays the existing transaction response safely.
* **Conflict Resolution:** DynamoDB utilizes a Last-Write-Wins (LWW) timestamp-based conflict resolution mechanism for concurrent attribute updates, supplemented by application-level validation rules.

### 5.3 Amazon ElastiCache Redis Cluster (Global Datastore)
* **Transient Data & Caching:** ElastiCache Redis clusters in both regions are linked via Global Datastore architecture.
* **Use Cases:** Rate-limiting token buckets, merchant configuration parameters, and short-lived session tokens are synchronized across regions in near real-time, ensuring consistent API throttling limits globally.

### 5.4 Amazon MSK Kafka (Event-Driven Messaging)
* **Dual-Cluster Synchronization:** Both Mumbai and Hyderabad operate independent 6-broker Amazon MSK clusters handling ~50,000 messages per second.
* **Replication Mechanism:** Cross-region topic synchronization is achieved using Apache Kafka MirrorMaker 2, mirroring critical event streams (`Transaction Events`, `Settlement Triggers`, `Webhook Deliveries`, `Audit Log Ingestion`).
* **Consumer Idempotency:** All downstream consumer pods in EKS are engineered to be strictly idempotent, ensuring that duplicate event processing resulting from cross-region replay or failover events does not cause duplicate merchant settlements or double payouts.

---

## 6. Comprehensive Architecture Comparison Matrix

To evaluate the engineering trade-offs between the Active-Passive and Active-Active multi-region strategies implemented by PaySecure, the following comparison matrix summarizes key operational dimensions:

| Architectural Dimension | Active-Passive (Disaster Recovery) | Active-Active (Multi-Master Global) |
| :--- | :--- | :--- |
| **Primary Traffic Distribution** | 100% traffic routed to Mumbai; Hyderabad acts as a warm standby. | Traffic distributed concurrently across both Mumbai and Hyderabad. |
| **Resource Utilization** | Low compute footprint in Hyderabad; scales up during failover. | High active utilization across both regions; maximizes infrastructure ROI. |
| **Recovery Time Objective (RTO)** | $\le 15 \text{ minutes}$ (DNS switch + pod autoscaling + DB promotion). | Near-Zero ($\approx 0$ seconds via automated DNS health rerouting). |
| **Recovery Point Objective (RPO)** | $\le 5 \text{ minutes}$ (Asynchronous replication lag bounds). | Near-Zero (Multi-master synchronous/fast-async replication streams). |
| **Infrastructure Complexity** | Moderate; straightforward standby scaling and promotion logic. | High; requires complex conflict resolution, state synchronization, and idempotency handling. |
| **Cost Profile** | Cost-effective; minimal compute overhead in secondary datacenter. | Higher cost due to duplicated production compute and multi-region storage sizing. |
| **Compliance & Security** | Full PCI DSS / CDE isolation within Indian sovereign boundaries. | Full PCI DSS / CDE isolation with synchronized multi-region AWS KMS keys. |

---

## 7. Security, Compliance, and Observability

Maintaining rigorous security and compliance standards across a multi-region active-active footprint is mandatory under Indian banking regulations and PCI DSS frameworks.

### 7.1 PCI DSS & Cardholder Data Environment (CDE) Boundary
* **Strict Segmentation:** The `tokenisation-service` and all cardholder data processing microservices are strictly isolated within dedicated subnets protected by security groups, network ACLs, and Istio mTLS authorization policies in both Mumbai and Hyderabad.
* **Cryptographic Key Management:** AWS KMS multi-Region keys are utilized to ensure that encrypted payloads can be securely decrypted across regions without exposing plaintext card data over transit paths. Secrets Manager orchestrates automated 90-day credential rotation across both environments.

### 7.2 Centralized Observability & Incident Management
* **Metrics & Telemetry:** Prometheus collectors in each region stream operational metrics to centralized Grafana dashboards.
* **Log Aggregation:** FluentBit ships container logs from all ~360 total pods (across both regions) into a centralized ELK (Elasticsearch, Logstash, Kibana) stack.
* **Distributed Tracing & Alerting:** Jaeger provides end-to-end distributed tracing across microservice boundaries, while PagerDuty integrates with Amazon CloudWatch alarms and AWS GuardDuty threat detections to alert on-call Site Reliability Engineers (SREs) instantly upon anomaly detection.

---

## 8. Conclusion and Future Roadmap

The transition from a single-region Mumbai footprint to a robust **Active-Active Multi-Region Architecture** across Mumbai and Hyderabad represents a transformative milestone for PaySecure Gateway Private Limited. By distributing production traffic, enforcing multi-master state synchronization via DynamoDB and Aurora Global Databases, and deploying resilient event streaming via MSK Kafka, PaySecure achieves an elite standard of high availability, regulatory compliance, and fault tolerance.

Future roadmap enhancements will incorporate automated chaos engineering drills using AWS Fault Injection Simulator (FIS) to validate failover behavior under simulated network partitions, alongside advanced machine learning models for real-time cross-region fraud detection synchronization.
"""