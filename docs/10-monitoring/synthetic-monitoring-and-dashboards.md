# Synthetic Monitoring and DR Dashboard Specification

## 1. Purpose

Passive monitoring observes production traffic but cannot prove that the recovery path works when traffic is low or a dependency has not yet failed. This specification defines synthetic checks that continuously validate Mumbai (`ap-south-1`) and Hyderabad (`ap-south-2`) and the dashboards used by each operational audience.

Synthetic tests must use dedicated test merchants, non-production payment instruments, and idempotency keys prefixed with `synthetic-{region}-{timestamp}`. They must never move real funds or expose cardholder data.

## 2. Synthetic Checks

### 2.1 End-to-End Synthetic Payment

- **Frequency:** Every 60 seconds in both regions.
- **Path:** API request -> authentication -> tokenisation test -> transaction write -> idempotency write -> settlement queue event -> status read.
- **Endpoint:** `https://{region-api}/synthetic/v1/payment-check`.
- **Success criteria:** HTTP 2xx, total duration below 300 ms at P99, exactly one transaction ID, exactly one idempotency record, and exactly one settlement event.
- **Failure response:** Page P1 when two consecutive checks fail in one region; page P1 immediately when both regions fail. Disable the synthetic merchant on any unexpected debit or duplicate event.
- **Evidence:** Store request ID, region, latency, response class, transaction ID hash, event ID hash, and cleanup status. Do not store PAN, CVV, or response secrets.

### 2.2 DNS Resolution Verification

- **Frequency:** Every 60 seconds from at least three independent probe locations.
- **Checks:** Resolve `api.paysecure.example` using the configured recursive resolvers and compare the answer with the currently approved ALB targets and Route 53 failover state.
- **Success criteria:** DNS answer is an approved endpoint, TTL is within the configured 10-60 second range, DNSSEC validation succeeds, and the answer agrees across probes.
- **Failure response:** Alert on an unauthorized IP, disagreement between probes, DNSSEC failure, or unexpected primary/secondary state. Freeze DNS changes and invoke RB-03.
- **Evidence:** Resolver, timestamp, answer, TTL, DNSSEC result, and Route 53 change ID.

### 2.3 Cross-Region Connectivity

- **Frequency:** Probe every 30 seconds; publish rolling 1-minute and 5-minute aggregates.
- **Checks:** TCP/TLS connectivity between regional private endpoints, round-trip latency, packet loss, jitter, Transit Gateway attachment state, and replication endpoint reachability.
- **Success criteria:** Mumbai-Hyderabad RTT remains within the measured baseline, packet loss stays below 1%, and no replication endpoint is unreachable.
- **Failure response:** P2 for RTT above baseline plus 25% for 3 minutes; P1 for packet loss above 2% for 60 seconds or replication interruption. Invoke RB-05 when both regions remain healthy but replication fails.
- **Evidence:** Probe source/target, p50/p95/p99 latency, packet loss, jitter, route state, and replication lag.

### 2.4 Certificate Expiry and Trust

- **Frequency:** Check every 6 hours; evaluate every certificate at 30, 14, 7, and 1 day thresholds.
- **Checks:** ACM status, certificate expiration, SAN/hostname match, issuer chain, TLS protocol/cipher policy, and ALB listener association in both regions.
- **Success criteria:** Certificate is issued, unexpired, hostname-valid, attached to the intended listener, and trusted by the supported client matrix.
- **Failure response:** P2 at 30/14/7 days; P1 at 1 day or any active TLS failure. Invoke RB-09 and retain the current certificate until replacement validation passes.
- **Evidence:** Certificate ARN hash, expiry, SANs, listener ARN, validation status, and alert timestamp.

### 2.5 Backup Restore Verification

- **Frequency:** Weekly, during an approved maintenance window.
- **Checks:** Restore an Aurora snapshot or point-in-time copy into an isolated account/VPC; restore representative S3 objects and verify versioning; verify DynamoDB point-in-time recovery metadata.
- **Success criteria:** Restore completes within the recovery budget, database integrity checks pass, representative transaction counts reconcile, objects decrypt with the recovery key, and no production endpoint is exposed.
- **Failure response:** P1 if no valid restore exists; P2 if restore exceeds the target or an individual object class fails. Freeze claims about RPO until the test passes.
- **Evidence:** Backup ARN, restore timestamp, duration, checksum, row-count/reconciliation result, encryption result, and cleanup confirmation.

## 3. Alert Routing and Ownership

| Signal | Threshold | Severity | Owner | Runbook |
|---|---|---|---|---|
| Synthetic payment | 2 consecutive failures in one region | P1 | Application SRE | RB-01/RB-12 |
| DNS answer | Unauthorized answer or DNSSEC failure | P1 | Network/Security | RB-03 |
| Cross-region packet loss | >2% for 60 seconds | P1 | Network | RB-05 |
| Cross-region latency | >25% above measured baseline for 3 minutes | P2 | Network/Data | RB-05 |
| Certificate | <=1 day or active handshake failure | P1 | Security/SRE | RB-09 |
| Backup restore | No valid restore or integrity failure | P1 | DBA | RB-02/RB-11 |

Alerts must be delivered through PagerDuty and a secondary out-of-band channel. The monitoring system must continue collecting from Hyderabad when Mumbai is unavailable.

## 4. Dashboard Specifications

### 4.1 DR Readiness Dashboard

- **Audience:** Platform Engineering, VP Engineering
- **Refresh:** 30 seconds
- **Panels:** Aurora, DynamoDB, Redis, MSK, and S3 replication lag; both-region health checks; last drill date/result; RPO/RTO status; estimated failover time; synthetic payment result.
- **Red:** Any component above its RPO threshold, missing backup restore, or failed synthetic payment.

### 4.2 Incident Response Dashboard

- **Audience:** On-call Engineer, Incident Commander
- **Refresh:** 10 seconds
- **Panels:** Regional availability map; transaction success rate; P99 latency; per-microservice errors; active alerts by severity; deployment history; current writer; DNS answer; runbook links.
- **Required interaction:** Filter every panel by region and incident ID.

### 4.3 Executive DR Summary

- **Audience:** CTO, CRO, Compliance Head
- **Refresh:** 5 minutes
- **Panels:** Trailing 30-day uptime; DR readiness score; cost versus budget; upcoming drill; open compliance findings; last incident summary; unresolved financial exposure.
- **Red:** Availability below 99.99%, overdue drill, open P1 finding, or unclosed reconciliation item.

### 4.4 Merchant Impact Dashboard

- **Audience:** Merchant Relations, Support
- **Refresh:** 1 minute
- **Panels:** Success rate by merchant segment; affected payment methods; degraded-service notices; estimated restoration time; affected merchant count; communication status; unknown transaction count.
- **Privacy:** Show aggregate segments only; do not expose payment credentials or full transaction identifiers.

### 4.5 Cost Tracking Dashboard

- **Audience:** Finance, VP Engineering
- **Refresh:** 15 minutes
- **Panels:** Daily spend by region; DR utilization; reserved versus on-demand capacity; projected monthly cost; transfer cost; cost anomalies; cost by DR tier.
- **Alert:** Notify Finance when forecast exceeds the approved monthly budget by 10%.

## 5. Weekly Evidence and Review

The SRE lead reviews synthetic success, DNS convergence, connectivity, certificate age, and backup-restore evidence weekly. The DBA signs backup results, Security signs certificate/DNS results, and the Incident Commander signs any missed threshold. Failed checks create a tracked corrective action with an owner and due date.
