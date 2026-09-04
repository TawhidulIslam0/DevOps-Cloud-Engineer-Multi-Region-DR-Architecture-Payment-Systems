# Multi-Region Data Replication Sequence Diagrams

## 1. Overview

This document provides Mermaid sequence diagrams for the PaySecure multi-region disaster recovery architecture.

The diagrams show the application write path, read path, replication behavior, and regional failover behavior across AWS Mumbai (`ap-south-1`) and AWS Hyderabad (`ap-south-2`).

The diagrams cover:

1. Normal-state write path
2. Normal-state read path
3. Normal-state cross-region replication
4. Failover write path
5. Failover read path
6. Post-failover replication and recovery

The architecture uses different replication strategies for each stateful service. Aurora PostgreSQL uses Aurora Global Database with controlled writer ownership. DynamoDB uses Global Tables for replicated session and idempotency state. Redis provides regional caching with replication or rebuild capability. Amazon MSK replicates critical Kafka topics between regional clusters. S3 uses cross-region object replication.

The project recovery targets are:

- Availability: 99.99%
- RPO: less than 1 minute
- RTO: less than 5 minutes

---

# 2. Normal-State Write Path

During normal operation, Mumbai (`ap-south-1`) is the primary production region.

Customer payment traffic enters through the global routing layer and reaches the Mumbai application stack.

The transaction is validated, an idempotency key is checked, the authoritative transaction is written to Aurora, and downstream events are published to Kafka.

```mermaid
sequenceDiagram
    autonumber

    participant Client as Merchant / Client
    participant R53 as Route 53
    participant ALB_M as Mumbai ALB
    participant API_M as Mumbai payment-api
    participant DDB_M as DynamoDB Mumbai
    participant Aurora_M as Aurora Mumbai Writer
    participant Kafka_M as Mumbai MSK
    participant Worker_M as Mumbai Event Consumers
    participant DDB_H as DynamoDB Hyderabad
    participant Aurora_H as Aurora Hyderabad Secondary
    participant Kafka_H as Hyderabad MSK

    Client->>R53: Payment request
    R53->>ALB_M: Route to healthy Mumbai endpoint
    ALB_M->>API_M: Forward HTTPS request

    API_M->>DDB_M: Check idempotency key

    alt Idempotency key already exists
        DDB_M-->>API_M: Existing transaction found
        API_M-->>Client: Return existing transaction result
    else New idempotency key
        DDB_M-->>API_M: Key not found

        API_M->>DDB_M: Create idempotency record
        API_M->>Aurora_M: Begin transaction
        Aurora_M-->>API_M: Transaction committed

        API_M->>Kafka_M: Publish Transaction Event
        Kafka_M->>Worker_M: Deliver event
        Worker_M-->>Kafka_M: Commit processing offset

        Aurora_M-->>Aurora_H: Cross-region replication
        DDB_M-->>DDB_H: Global Table replication
        Kafka_M-->>Kafka_H: Replicate event and metadata

        API_M-->>Client: Payment accepted
    end