# DR Drill Success Criteria

## 1. Purpose

This document defines the measurable pass/fail criteria used to evaluate PaySecure's disaster recovery drills.

The criteria provide a consistent method for determining whether the DR architecture, runbooks, operational processes, data replication, application recovery, security controls, monitoring, and communications perform as designed.

The primary recovery objectives are:

- **Availability target:** 99.99%
- **RTO:** less than 5 minutes
- **RPO:** less than 1 minute
- **Primary region:** AWS Mumbai (`ap-south-1`)
- **DR region:** AWS Hyderabad (`ap-south-2`)

A drill is considered successful only when the critical recovery objectives and transaction-integrity requirements are satisfied.

---

## 2. Success Classification

Each drill receives one of four final classifications.

| Result | Definition |
|---|---|
| **PASS** | All critical success criteria are met |
| **PASS WITH OBSERVATIONS** | Critical criteria pass, but non-critical improvements are identified |
| **CONDITIONAL PASS** | Recovery succeeds but one or more important targets are missed |
| **FAIL** | A critical recovery, security, data-integrity, or operational objective fails |

A drill may not be marked PASS when a critical financial-data integrity issue remains unresolved.

---

# 3. Recovery Time Objective

## Target

**RTO < 5 minutes**

RTO is measured from the defined recovery trigger until the critical application path is operational in the recovery environment.

### Start timestamp

The RTO clock starts when the Incident Commander officially declares that regional or service recovery is required.

### End timestamp

The RTO clock stops when:

1. The recovery endpoint is healthy.
2. Critical application dependencies are available.
3. A valid test transaction succeeds.
4. Monitoring confirms stable operation.

### RTO calculation

```text
RTO = Recovery Service Ready Timestamp
      - Recovery Decision Timestamp