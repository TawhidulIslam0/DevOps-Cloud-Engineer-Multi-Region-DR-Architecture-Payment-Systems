# AWS Regional Pricing Research — ap-south-1 and ap-south-2

**Project:** PaySecure Multi-Region Disaster Recovery Architecture  
**Purpose:** Initial AWS pricing research for the DR cost model  
**Primary Region:** ap-south-1 — Asia Pacific (Mumbai)  
**DR Region:** ap-south-2 — Asia Pacific (Hyderabad)  
**Pricing Model:** On-Demand unless otherwise stated  
**Currency:** USD  
**Research Date:** September 2026  
**Status:** Initial research — final cost model to be completed during Day 14–15

---

## 1. Research Scope

This document begins the AWS cost-analysis research required for the PaySecure
multi-region disaster recovery architecture.

The objective is to identify the pricing dimensions and representative
On-Demand rates that will be required for the final cost model covering:

- Cold standby
- Warm standby
- Hot standby
- Active-active

The two AWS regions evaluated are:

| Region | AWS Region Code | AWS Billing Code | Role |
|---|---|---|---|
| Mumbai | `ap-south-1` | APS3 | Primary |
| Hyderabad | `ap-south-2` | APS5 | Disaster Recovery |

AWS officially lists `ap-south-1` as Asia Pacific (Mumbai) and `ap-south-2`
as Asia Pacific (Hyderabad). The corresponding AWS billing codes are APS3
and APS5.

> **Important:** AWS prices can change. Exact production estimates should be
> generated with the AWS Pricing Calculator or AWS Price List API immediately
> before final submission. Values in this document are research inputs rather
> than a binding quotation.

---

## 2. Pricing Methodology

The final DR cost model will calculate:

```text
Monthly Cost =
    Compute
  + Kubernetes
  + Database
  + Cache
  + Messaging
  + Storage
  + Networking
  + Security
  + Monitoring
  + DNS
  + Data Transfer
  + Backup / Replication