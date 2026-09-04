# Data Sovereignty Data-Flow Diagrams

## 1. Purpose

This document illustrates the movement of PaySecure Gateway data between AWS Mumbai (`ap-south-1`) and AWS Hyderabad (`ap-south-2`).

The diagrams cover:

- Normal production data flows
- Cross-region replication
- Regional failover
- Hyderabad production operation
- Failback to Mumbai
- Data classification boundaries
- Security controls
- Replication direction

The architecture uses Mumbai as the normal production region and Hyderabad as the disaster recovery region.

The target recovery objectives are:

- Availability: 99.99%
- RPO: <1 minute
- RTO: <5 minutes

---

# 2. Regional Overview

```mermaid
flowchart LR

    U[Clients / Payment Partners]

    subgraph M["AWS Mumbai - ap-south-1"]
        MA[Application Load Balancer]
        ME[EKS Microservices]
        AD[(Aurora PostgreSQL Primary)]
        DD[(DynamoDB)]
        RD[(ElastiCache Redis)]
        MK[MSK Kafka]
        MS[S3]
        MKMS[KMS / Secrets Manager]
    end

    subgraph H["AWS Hyderabad - ap-south-2"]
        HA[Application Load Balancer]
        HE[EKS DR Microservices]
        HD[(Aurora PostgreSQL Secondary)]
        DH[(DynamoDB Replica)]
        RH[(ElastiCache Redis)]
        HK[MSK Kafka]
        HS[S3]
        HKMS[KMS / Secrets Manager]
    end

    U --> MA
    MA --> ME

    ME --> AD
    ME --> DD
    ME --> RD
    ME --> MK
    ME --> MS
    ME --> MKMS

    AD -. "Cross-region replication" .-> HD
    DD <-. "Global Tables replication" .-> DH
    RD -. "Global Datastore / rebuild" .-> RH
    MK -. "MSK replication" .-> HK
    MS -. "S3 CRR" .-> HS

    MKMS -. "Controlled security configuration" .-> HKMS