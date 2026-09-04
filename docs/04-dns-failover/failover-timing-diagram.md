# DNS Failover Timing Analysis

## 1. Purpose

This document defines the expected timing sequence for regional DNS failover in the PaySecure Gateway multi-region disaster recovery architecture.

The design uses Amazon Route 53 failover routing with Mumbai (`ap-south-1`) as the primary region and Hyderabad (`ap-south-2`) as the secondary region.

The project recovery targets are:

- **Availability:** 99.99%
- **RPO:** <1 minute
- **RTO:** <5 minutes

The timing model is an engineering target for the complete recovery process. Route 53 DNS failover alone does not guarantee the full RTO because database promotion, application readiness, DNS caching, and operational validation also contribute to recovery time.

---

## 2. Normal Operating State

Under normal conditions, Mumbai receives production traffic.

```mermaid
sequenceDiagram
    participant U as User
    participant R as Route 53
    participant M as Mumbai ALB
    participant E as Mumbai EKS
    participant D as Mumbai Data Layer

    U->>R: DNS query for api.paysecure.example
    R->>R: Check primary health status
    R-->>U: Return Mumbai ALB
    U->>M: HTTPS request
    M->>E: Forward request
    E->>D: Read/write application data
    D-->>E: Response
    E-->>M: Application response
    M-->>U: HTTPS response