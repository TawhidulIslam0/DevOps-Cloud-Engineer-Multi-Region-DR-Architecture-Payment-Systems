# PaySecure DR Failure Mode and Effects Analysis

## 1. Purpose and Method

This FMEA prioritizes failure modes that could prevent PaySecure from meeting its RTO below five minutes, RPO below one minute, 99.99% availability target, or financial-integrity obligations. Scores use a 1-10 scale:

- **Severity (S):** 1 = negligible impact; 10 = financial-integrity, security, or regional outage impact.
- **Occurrence (O):** 1 = rare; 10 = frequent or highly likely without controls.
- **Detection (D):** 1 = detected immediately; 10 = difficult to detect before impact.
- **Risk Priority Number (RPN):** `S x O x D`.

The scores are planning estimates and must be recalibrated from incident and drill evidence. The highest-RPN risks receive the earliest engineering and testing investment.

## 2. FMEA Register

| ID | Component | Failure mode | Effect | S | O | D | RPN | Primary mitigation |
|---|---|---|---|---:|---:|---:|---:|---|
| FMEA-01 | Aurora PostgreSQL | Writer instance crash | Payment writes fail or time out | 9 | 3 | 2 | 54 | Multi-AZ failover, Aurora health alarms, writer verification |
| FMEA-02 | Aurora PostgreSQL | Storage or logical corruption | Incorrect transaction status or ledger data | 10 | 2 | 5 | 100 | PITR, immutable backups, integrity and reconciliation checks |
| FMEA-03 | Aurora Global Database | Replication lag exceeds RPO | Hyderabad promotion loses recent writes | 9 | 4 | 3 | 108 | Lag P1 alarm, promotion gate at 60 seconds, controlled approval |
| FMEA-04 | Aurora Global Database | Dual writers after partition | Duplicate or conflicting ledger updates | 10 | 2 | 7 | 140 | Writer fencing, single-writer verification, partition runbook |
| FMEA-05 | DynamoDB Global Tables | Last-writer-wins conflict | Idempotency record is overwritten | 9 | 3 | 6 | 162 | Key design, conditional writes, conflict metrics, reconciliation |
| FMEA-06 | DynamoDB | Capacity exhaustion | Requests throttle and retries create load | 8 | 4 | 3 | 96 | Auto scaling, throttling alarms, bounded retry budgets |
| FMEA-07 | ElastiCache Redis | Global Datastore replication lag | Stale sessions, configuration, or rate limits | 6 | 5 | 4 | 120 | Lag alarms, cache rebuild path, database as source of truth |
| FMEA-08 | ElastiCache Redis | Cache loss during promotion | Latency spike or database overload | 7 | 4 | 4 | 112 | Warm-up procedure, connection limits, database overload alarms |
| FMEA-09 | MSK Kafka | Broker or quorum failure | Settlement and audit events stop | 9 | 3 | 3 | 81 | Multi-AZ brokers, under-replicated partition alarms, replay plan |
| FMEA-10 | MSK Replicator | Cross-region replication halt | DR event stream is stale | 8 | 4 | 5 | 160 | Replicator lag alarm, checkpoint evidence, controlled replay |
| FMEA-11 | Route 53 | Health-check false positive | Unnecessary traffic failover | 7 | 3 | 3 | 63 | Multi-signal checks, approval gate, synthetic validation |
| FMEA-12 | Route 53 | Health-check false negative | Failed region continues receiving traffic | 9 | 2 | 7 | 126 | Independent probes, DNS monitoring, application-level checks |
| FMEA-13 | DNS/IAM | Unauthorized record change | Traffic redirected to an untrusted endpoint | 10 | 2 | 8 | 160 | DNSSEC, least privilege, CloudTrail alerts, signed change batches |
| FMEA-14 | EKS | Node or AZ capacity loss | Pods remain pending and capacity falls below peak | 8 | 4 | 3 | 96 | Three-AZ spread, HPA, PDB, node readiness alarms |
| FMEA-15 | EKS deployment | Bad image or configuration rollout | Payment API or dependency becomes unhealthy | 8 | 4 | 4 | 128 | Readiness gates, canary rollout, image pinning, rollback |
| FMEA-16 | Cross-region network | Transit Gateway or VPN partition | Replication stops and split-brain becomes possible | 10 | 2 | 6 | 120 | Packet-loss probes, fencing, route validation, partition drill |
| FMEA-17 | KMS | Key or grant compromise | Encrypted cardholder data may be exposed | 10 | 1 | 8 | 80 | Key rotation, grant review, CloudTrail, re-encryption plan |
| FMEA-18 | CI/CD | Single-region deployment drift | DR runs stale or untrusted software | 8 | 4 | 5 | 160 | Dual-region pipeline, drift detection, signed artifacts |
| FMEA-19 | Backups/S3 | Restore or replication failure | Recovery data is unavailable or stale | 10 | 2 | 7 | 140 | Versioning, immutable backups, weekly restore tests, CRR alarms |
| FMEA-20 | Monitoring | Monitoring control-plane failure | Regional failure or lag is detected late | 9 | 3 | 7 | 189 | Independent monitoring, cross-region dashboards, synthetic checks |

## 3. Priority Actions

| Priority | Risks | Required action |
|---|---|---|
| P1 | FMEA-20, FMEA-05, FMEA-10, FMEA-13, FMEA-18 | Build independent monitoring, conflict detection, replication alarms, protected DNS changes, and dual-region deployment drift checks. |
| P1 | FMEA-04, FMEA-19 | Exercise writer fencing and backup restoration before any regional failover approval. |
| P2 | FMEA-03, FMEA-07, FMEA-08, FMEA-12, FMEA-15, FMEA-16 | Add quantified gates to failover, cache warm-up, DNS validation, rollout, and partition drills. |
| P3 | FMEA-01, FMEA-02, FMEA-06, FMEA-09, FMEA-11, FMEA-14, FMEA-17 | Maintain existing controls and verify them through component drills and quarterly reviews. |

## 4. Validation Metrics

The following evidence updates the scores after each drill or incident:

- Time from failure injection to alert.
- Replication lag at detection and promotion.
- Number of unknown, duplicate, or unreconciled transactions.
- Number of database writers during the incident.
- DNS convergence time from independent resolvers.
- Backup restore success rate and restore duration.
- Percentage of critical services restored within the target RTO.
- Number of unauthorized, stale, or drifted regional resources.

The FMEA must be reviewed after every full regional drill, security incident, material architecture change, and quarterly risk review.
