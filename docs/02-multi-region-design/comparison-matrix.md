# Active-Active vs Active-Passive Comparison Matrix

## 1. Purpose

This document compares the two proposed multi-region disaster recovery architectures for PaySecure Gateway:

1. Active-Passive
2. Active-Active

The comparison considers technical resilience, transaction integrity, recovery objectives, cost, complexity, data consistency, operational burden, and regulatory requirements.

The project requires a multi-region design capable of achieving 99.99% availability, RPO below one minute, and RTO below five minutes.

The comparison therefore evaluates the architectures against these target outcomes rather than simply comparing generic cloud DR patterns.

---

## 2. Executive Comparison

| Dimension | Active-Passive | Active-Active |
|---|---|---|
| Primary traffic model | Mumbai 100%, Hyderabad standby | Mumbai + Hyderabad concurrently |
| Normal traffic | Single region | Both regions |
| Regional failure | Promote Hyderabad | Remove failed region from routing |
| Target RTO | < 5 minutes | < 5 minutes |
| Target RPO | < 1 minute | < 1 minute |
| Normal database writer model | Mumbai writer | Controlled regional transaction ownership |
| Database replication | Aurora Global Database | Aurora Global Database + ownership controls |
| DynamoDB | Multi-region replicated state | Global Tables active-active |
| Redis | Replicated standby/cache | Multi-region cache strategy |
| Kafka | Cross-region replication | Cross-region active-active replication |
| Cost | Lower | Higher |
| Complexity | Medium | High |
| Split-brain risk | Lower | Higher |
| Transaction conflict risk | Lower | Higher |
| Operational burden | Lower | Higher |
| Peak capacity requirement | DR must scale rapidly | Each region must be able to absorb full load |
| Regulatory complexity | Lower | Higher |
| Failover automation | Required | Required |
| Reconciliation requirement | High | Very high |
| Recommended baseline | Yes | Conditional |

---

## 3. RTO Comparison

### Active-Passive

Target:

```text
RTO < 5 minutes