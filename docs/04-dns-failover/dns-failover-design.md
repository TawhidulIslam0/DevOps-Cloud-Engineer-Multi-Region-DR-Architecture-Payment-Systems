# DNS Failover Design

## 1. Executive Summary

This document defines the DNS-based regional failover strategy for the PaySecure Gateway multi-region disaster recovery architecture.

The production environment operates primarily in AWS Mumbai (`ap-south-1`), while AWS Hyderabad (`ap-south-2`) provides the disaster recovery and secondary operating environment.

Amazon Route 53 is used as the authoritative DNS service for the application endpoint. A failover routing policy provides a primary record for Mumbai and a secondary record for Hyderabad. Route 53 health checks determine whether the primary endpoint should continue receiving DNS responses.

The DNS failover design supports the project's recovery objectives:

- Availability target: 99.99%
- RPO: less than 1 minute
- RTO: less than 5 minutes

DNS failover is only one part of the recovery process. Route 53 determines where new DNS resolutions should be directed, while database promotion, application readiness, Kafka recovery, security validation, and operational approval are handled by the disaster recovery workflow.

---

## 2. Objectives

The DNS failover design must:

1. Direct normal application traffic to Mumbai.
2. Detect loss of application availability in Mumbai.
3. Remove the unhealthy Mumbai endpoint from normal DNS responses.
4. Direct new DNS resolutions to Hyderabad.
5. Maintain a short DNS TTL to reduce client-side caching delays.
6. Prevent DNS failover from occurring because of a temporary application-level problem.
7. Support controlled disaster recovery testing.
8. Provide sufficient observability for operators.
9. Avoid creating split-brain application writes.
10. Support recovery within the project's five-minute RTO target.

---

## 3. Regional Architecture

### Primary Region

**AWS Mumbai (`ap-south-1`)**

Mumbai is the normal production region.

```text
Users
  |
  v
Route 53
  |
  | PRIMARY
  v
Mumbai ALB
  |
  v
AWS WAF
  |
  v
EKS Production Cluster
  |
  +--> Aurora PostgreSQL
  +--> DynamoDB
  +--> ElastiCache Redis
  +--> MSK Kafka