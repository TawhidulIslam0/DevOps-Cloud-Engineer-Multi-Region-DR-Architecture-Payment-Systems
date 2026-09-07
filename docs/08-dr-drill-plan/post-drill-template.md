# Post-DR Drill Report Template

## 1. Drill Identification

| Field | Details |
|---|---|
| Drill ID | DR-YYYY-MM |
| Drill Name | |
| Drill Date | |
| Start Time | |
| End Time | |
| Drill Type | Component / Service / Regional / Full DR |
| Primary Region | `ap-south-1` Mumbai |
| DR Region | `ap-south-2` Hyderabad |
| Incident Commander | |
| DR Lead | |
| Scribe | |
| Business Owner | |
| Related Runbooks | |

---

# 2. Drill Objectives

## Primary Objective

Describe the recovery capability being tested.

## Secondary Objectives

1. 
2. 
3. 
4. 
5. 

## Expected Recovery Objectives

- **Target RTO:** < 5 minutes
- **Target RPO:** < 1 minute
- **Availability target:** 99.99%
- **Critical transaction loss:** 0
- **Duplicate financial transactions:** 0

---

# 3. Scope

### Components Tested

- [ ] EKS
- [ ] ALB
- [ ] AWS WAF
- [ ] Aurora PostgreSQL
- [ ] DynamoDB
- [ ] ElastiCache
- [ ] Amazon MSK
- [ ] Amazon S3
- [ ] Route 53
- [ ] KMS
- [ ] Secrets Manager
- [ ] Transit Gateway
- [ ] Partner connectivity
- [ ] Monitoring
- [ ] Critical microservices

### Out of Scope

Document systems or activities intentionally excluded from the exercise.

---

# 4. Participants

| Role | Name | Responsibility |
|---|---|---|
| Incident Commander | | Overall command |
| DR Lead | | Recovery coordination |
| Platform/EKS Lead | | Kubernetes and compute |
| Database Lead | | Aurora/DynamoDB |
| Messaging Lead | | MSK |
| Network Lead | | DNS/networking |
| Security Lead | | Security controls |
| Observability Lead | | Monitoring/logging |
| Application Lead | | Microservices |
| Compliance Lead | | Compliance/data sovereignty |
| Communications Lead | | Stakeholder communications |
| Scribe | | Timeline/evidence |

---

# 5. Pre-Drill Baseline

Record the system state immediately before the drill.

| Metric | Baseline |
|---|---:|
| Application TPS | |
| API latency | |
| EKS healthy nodes | |
| EKS ready pods | |
| Aurora replication lag | |
| DynamoDB replication status | |
| MSK consumer lag | |
| Redis health | |
| ALB healthy targets | |
| DNS resolution | |
| Active database writer | |
| Critical alerts | |

### Baseline Evidence

Dashboard references:

- CloudWatch:
- Prometheus:
- Grafana:
- ELK:
- Jaeger:
- PagerDuty:

---

# 6. Scenario Description

## Failure Scenario

Describe the simulated failure.

Example:

> A simulated regional outage affects the Mumbai production environment. The exercise requires recovery in the Hyderabad DR region.

## Expected Detection

Describe how the failure should be detected.

Expected signals may include:

- CloudWatch alarms
- Prometheus alerts
- Route 53 health-check failure
- Application health-check failure
- Customer reports
- Replication-lag alerts
- Infrastructure alerts

---

# 7. Timeline

Record every significant event.

| Time | Event | Owner | Evidence |
|---|---|---|---|
| | Failure injected | | |
| | Alert generated | | |
| | Incident declared | | |
| | Diagnosis started | | |
| | Recovery decision | | |
| | Failover initiated | | |
| | Database recovery/promotion | | |
| | DNS change | | |
| | Application recovery | | |
| | First successful test transaction | | |
| | Recovery validated | | |
| | Failback started | | |
| | Failback completed | | |
| | Drill ended | | |

---

# 8. Detection Assessment

## Detection Result

- Detection successful: YES / NO
- Detection time:
- Alert source:
- Alert accuracy:
- Escalation time:

### Assessment

Describe whether monitoring detected the failure quickly enough.

### Findings

1.
2.
3.

---

# 9. Diagnostic Assessment

## Diagnostic Result

- Correct failure domain identified: YES / NO
- Correct runbook selected: YES / NO
- Diagnostic commands successful: YES / NO
- Logs available: YES / NO
- Metrics available: YES / NO

### Diagnostic Time

```text
Detection Timestamp:
Diagnostic Start:
Failure Domain Identified:

Diagnostic Duration: