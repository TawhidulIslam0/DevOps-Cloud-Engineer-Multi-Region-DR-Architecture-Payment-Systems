# Multi-Region Data Replication Strategy

## 1. Executive Summary

This document defines the cross-region data replication strategy for the PaySecure Gateway multi-region disaster recovery architecture. The existing production environment operates in AWS Mumbai (`ap-south-1`), while the proposed disaster recovery and multi-region architecture introduces AWS Hyderabad (`ap-south-2`) as the secondary region.

The replication strategy covers the five stateful technology areas identified in the project requirements:

- Amazon Aurora PostgreSQL
- Amazon DynamoDB
- Amazon ElastiCache for Redis
- Amazon MSK Kafka
- Amazon S3

Each technology requires a different replication model because the data has different consistency, durability, latency, and recovery requirements.

The primary objectives are to support the project recovery targets of 99.99% availability, Recovery Point Objective (RPO) below one minute, and Recovery Time Objective (RTO) below five minutes.

The strategy separates critical financial state from reproducible or transient state. Transactional records, settlement information, idempotency keys, and important event streams require continuous or near-continuous replication. Cache data can be reconstructed when necessary, while application artifacts and audit objects should be replicated across regions to avoid recovery dependencies on the failed region.

The active-passive architecture maintains Mumbai as the normal write-authoritative production region and Hyderabad as the warm standby. The active-active architecture allows more regional resources to operate concurrently, but the underlying data services still require carefully controlled write ownership and conflict-management mechanisms.

---

## 2. Replication Design Principles

The replication strategy follows several principles.

### 2.1 Financial correctness takes priority over replication simplicity

Payment transactions cannot be treated like ordinary web application state. Losing or duplicating a transaction can result in incorrect settlement, duplicate payouts, merchant disputes, or regulatory issues.

Replication therefore prioritizes:

- Transaction integrity
- Idempotency
- Ordering
- Durable event delivery
- Controlled database promotion
- Duplicate detection
- Auditability

### 2.2 Critical state should be continuously replicated

Periodic backups alone are insufficient for the project's RPO target of less than one minute.

Critical state should therefore use managed cross-region replication where supported.

### 2.3 Replication must not create split-brain writes

A regional failover must establish clear write ownership.

For active-passive operation, Mumbai owns normal production writes. Hyderabad becomes the write-authoritative region only after controlled promotion.

For active-active operation, services that genuinely require writes in both regions must use a datastore designed for multi-region writes, such as DynamoDB Global Tables. Financial ledger writes stored in Aurora require controlled writer ownership because Aurora Global Database has one primary write Region and secondary read-only Regions. 

### 2.4 Recovery must not depend on the failed region

The Hyderabad environment must retain sufficient infrastructure, application artifacts, security configuration, and replicated data to operate independently if Mumbai becomes unavailable.

### 2.5 Replication must be observable

Replication health must be monitored continuously.

Important measurements include:

- Replication lag
- Replication errors
- Replication throughput
- Failed records
- Consumer lag
- Database promotion status
- Object replication status
- Cache synchronization health

---

# 3. Replication Architecture Overview

The proposed replication architecture is:

```text
                         PAYSECURE DATA REPLICATION

                  AWS Mumbai                  AWS Hyderabad
                  ap-south-1                  ap-south-2
                 ┌─────────────┐             ┌─────────────┐
                 │ Production  │             │ DR / Active │
                 │ Data Stores │             │ Data Stores │
                 └──────┬──────┘             └──────▲──────┘
                        │                             │
                        │                             │
        ┌───────────────┼─────────────────────────────┤
        │               │                             │
        │               │                             │
        ▼               ▼                             ▼
 Aurora Global     DynamoDB Global              MSK Replication
 Database          Tables                       / MSK Replicator
        │               │                             │
        │               │                             │
        ▼               ▼                             ▼
 Aurora Secondary  Regional Replica           Hyderabad Kafka
 in Hyderabad      in Hyderabad               Cluster
        │
        │
        └───────────────┐
                        │
                        ▼
                Redis Global Datastore
                / Cache Rebuild Strategy

                         S3
                          │
                          ▼
                  Cross-Region Replication