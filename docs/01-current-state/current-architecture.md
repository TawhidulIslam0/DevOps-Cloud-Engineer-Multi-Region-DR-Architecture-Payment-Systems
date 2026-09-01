# PaySecure Gateway — Current-State Architecture

## 1. Architecture Overview

PaySecure Gateway Private Limited currently operates its production payment platform entirely within the AWS Mumbai Region (`ap-south-1`). The platform is a fictional mid-tier payment aggregator processing approximately 3.2 million transactions per day, representing approximately ₹500 crore in daily transaction value across 45,000 merchants. Peak transaction throughput is approximately 1,200 transactions per second (TPS), with a current P99 transaction latency of approximately 180 milliseconds and current availability of 99.92%.

The existing architecture is designed as a highly available single-region deployment rather than a multi-region disaster recovery platform. Application workloads are distributed across three Availability Zones within the Mumbai region, providing resilience against individual Availability Zone failures. However, the architecture has no automated regional failover capability. A complete failure of the Mumbai region would therefore represent a major platform-wide failure domain.

The application tier is implemented on Amazon Elastic Kubernetes Service (EKS). The EKS cluster contains approximately 24 worker nodes distributed across three Availability Zones: `ap-south-1a`, `ap-south-1b`, and `ap-south-1c`. Approximately 180 Kubernetes pods run across 12 payment-platform microservices. Horizontal Pod Autoscaling is configured using CPU utilisation with a target of 60 percent as well as custom transaction-per-second-per-pod metrics.

## 2. Application and Microservice Layer

The twelve microservices running within EKS are:

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

External application traffic enters the environment through an AWS Application Load Balancer (ALB). AWS WAF provides protection at the application boundary before requests reach the Kubernetes workloads.

Within the EKS environment, inter-service communication is managed through the Istio service mesh. Mutual TLS (mTLS) is used for service-to-service communication, providing encrypted communication and an additional security boundary between application components.

The `payment-api` represents the primary entry point for payment-related application requests. Requests are processed by downstream services such as the transaction processor and fraud-detection service before transaction state is persisted. Settlement, notification, webhook, reconciliation, and audit functions operate as supporting services within the same application environment.

The rate-limiter provides protection against excessive request volume, while the health-monitor contributes to service health visibility. The merchant portal provides merchant-facing functionality, while tokenisation-service handles tokenised payment information within the payment-processing architecture.

## 3. Transactional Database Layer

The primary transactional database is Amazon Aurora PostgreSQL version 15.4. It is deployed as a Multi-AZ cluster containing one writer instance using the `db.r6g.2xlarge` instance class and two reader replicas.

Aurora stores several important categories of application data, including transaction records, merchant configurations, tokenised card data, and settlement batches. The database is therefore a critical stateful component of the payment platform.

A typical transaction flow reaches the application layer through the ALB and WAF and is processed by the relevant Kubernetes services. Persistent transaction state is written to Aurora PostgreSQL, while read operations can use the available reader replicas where appropriate.

A separate Amazon DynamoDB table provides session-management and idempotency-key functionality. The table uses provisioned capacity of approximately 10,000 read capacity units (RCU) and 5,000 write capacity units (WCU). Idempotency data is particularly important for a payment platform because it allows repeated requests to be associated with an existing transaction operation rather than unintentionally creating duplicate processing.

Amazon ElastiCache for Redis operates as the caching layer. Redis stores frequently accessed merchant configurations, rate-limiting counters, and frequently accessed transaction lookups. Because this information is used by application services during normal request processing, Redis reduces repeated database access and supports application performance.

## 4. Event Streaming and Messaging

Amazon Managed Streaming for Apache Kafka (MSK) provides the platform's event-streaming layer. The current MSK environment consists of six brokers and handles approximately 50,000 messages per second during peak periods.

Kafka topics support several important event categories, including transaction events, settlement triggers, webhook deliveries, and audit-log ingestion. This event-driven architecture allows processing responsibilities to be separated between services rather than requiring every operation to occur synchronously inside a single request.

For example, a transaction processed by the application tier can generate an event that downstream settlement, webhook, notification, reconciliation, or audit components consume. Kafka therefore represents another critical stateful dependency in the current architecture.

All Kafka topics currently use a seven-day retention policy. Although Kafka provides durability and replay capabilities within the region, the current architecture remains bounded by the Mumbai regional failure domain.

## 5. Network Architecture

All production services operate inside a dedicated AWS VPC using private subnets distributed across the three Mumbai Availability Zones.

The primary external request path is:

Internet → Application Load Balancer → AWS WAF → EKS application services.

The private network architecture limits direct exposure of internal workloads. Inter-service traffic remains inside the Kubernetes environment and is protected through the Istio service mesh and mTLS.

An AWS Transit Gateway connects the production VPC with the corporate network and partner bank VPN connections. This connectivity is important because PaySecure interacts with external financial and partner systems as part of its payment-processing environment.

AWS PrivateLink endpoints provide private connectivity from the environment to AWS services including Amazon S3, AWS Key Management Service (KMS), and AWS Secrets Manager. This reduces the need for application workloads to communicate with these services through public network paths.

## 6. Security and Compliance Boundaries

Security controls are integrated throughout the current architecture.

AWS KMS manages encryption keys used to protect data. AWS Secrets Manager stores sensitive operational credentials and secrets, including database credentials, API keys, and partner certificates. The project brief specifies automatic secret rotation every 90 days.

AWS CloudTrail provides account-level API auditing by recording AWS API activity. Amazon GuardDuty monitors for anomalous or potentially malicious activity.

A dedicated PCI DSS compliance boundary isolates the cardholder data environment (CDE). Strict network segmentation is used to separate the CDE from other workloads. This boundary is especially important because the platform processes payment-related information and must maintain strong controls around sensitive data.

The current architecture therefore contains several security layers: AWS WAF at the external application boundary, private VPC networking, Kubernetes service-to-service mTLS, encryption through KMS, secrets management, audit logging through CloudTrail, threat detection through GuardDuty, and PCI DSS network segmentation.

## 7. Observability and Operations

The current platform uses several monitoring and observability technologies.

Prometheus collects application and infrastructure metrics, while Grafana provides dashboards and visualisation. The monitoring environment currently covers approximately 2,400 metrics and approximately 350 active alerts.

The ELK stack — Elasticsearch, Logstash, and Kibana — provides centralised application and infrastructure log aggregation. PagerDuty integrates with CloudWatch alarms to provide incident alerting and operational escalation.

Jaeger provides distributed tracing across the microservices. This is particularly valuable in the current architecture because payment requests may pass through multiple services before completing.

Together, metrics, logs, alerts, and distributed tracing provide visibility into the health of the application and infrastructure layers.

## 8. Current Data Flow

The simplified transaction data flow is:

1. A merchant or payment client sends a request toward the PaySecure platform.
2. The request enters the AWS environment through the Application Load Balancer.
3. AWS WAF evaluates the incoming application traffic.
4. Valid traffic is forwarded to the EKS cluster.
5. The request reaches the appropriate payment microservices.
6. Services communicate through the Istio service mesh using mTLS.
7. Transactional state is persisted in Aurora PostgreSQL.
8. Session and idempotency information is maintained in DynamoDB.
9. Frequently accessed information and rate-limiting state may be served through ElastiCache Redis.
10. Transaction and downstream processing events are published to Amazon MSK.
11. Consumer services process settlement, webhook, notification, reconciliation, and audit events.
12. Metrics, logs, traces, and operational events are collected by the observability stack.

This architecture separates synchronous transaction processing from asynchronous downstream processing while maintaining multiple state-management systems for different workload requirements.

## 9. Failure Domains

The most important characteristic of the current architecture is that the platform has strong Availability Zone-level resilience but remains fundamentally a single-region system.

Within Mumbai, the EKS worker nodes are distributed across three Availability Zones. Aurora also provides Multi-AZ database availability, while the application tier is distributed across the same regional failure boundary.

A single Availability Zone failure should therefore be handled primarily through the existing multi-AZ architecture. However, a complete `ap-south-1` regional failure would simultaneously affect the EKS application tier, Aurora database, DynamoDB workloads, Redis cache, MSK cluster, networking components, and regional application endpoints.

The current architecture has no automated secondary-region failover mechanism. Consequently, a Mumbai regional outage represents a much larger failure domain than an individual node, pod, or Availability Zone failure.

This regional dependency is the primary architectural limitation that the subsequent multi-region disaster recovery design must address. The target architecture will need to preserve transaction integrity, minimise data loss, provide rapid traffic recovery, and maintain security and regulatory controls while introducing `ap-south-2` as a potential disaster recovery region.

## 10. Summary

PaySecure's current architecture is a distributed microservices platform operating entirely within AWS Mumbai. It combines EKS, Aurora PostgreSQL, DynamoDB, ElastiCache Redis, Amazon MSK, ALB, WAF, VPC networking, Istio, Transit Gateway, PrivateLink, KMS, Secrets Manager, CloudTrail, GuardDuty, and a comprehensive observability stack.

The architecture provides resilience within the Mumbai region through three Availability Zones and Multi-AZ services. However, its single-region design creates a significant regional failure domain. The absence of automated cross-region failover and replicated infrastructure means that a complete Mumbai outage could disrupt application processing, stateful services, event streaming, and external connectivity simultaneously.

The current-state analysis therefore establishes the baseline against which the project's later active-passive and active-active multi-region designs will be evaluated.