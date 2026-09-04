# Data Sovereignty and Compliance Matrix

## 1. Purpose

This document defines the data sovereignty and compliance considerations for the PaySecure Gateway multi-region architecture.

The architecture uses:

- AWS Mumbai (`ap-south-1`) as the primary production region.
- AWS Hyderabad (`ap-south-2`) as the secondary disaster recovery region.

The objective is to ensure that data replicated from Mumbai to Hyderabad remains subject to appropriate security, access-control, encryption, retention, and audit requirements.

The design does not assume that cross-region replication removes compliance obligations. Replicated copies must be governed using the same security and data-management principles as primary data.

---

## 2. Regional Data Model

```text
                         PAYSECURE DATA FLOW

                    AWS Mumbai
                    ap-south-1
                 PRIMARY REGION
                        |
                        |
              Cross-Region Replication
                        |
                        v
                    AWS Hyderabad
                    ap-south-2
                 DR / SECONDARY