# Annual Disaster Recovery Drill Plan

## 1. Purpose

This document defines PaySecure's 12-month disaster recovery (DR) testing and exercise program for the multi-region architecture.

The objective is to continuously validate that the DR architecture, replication mechanisms, DNS failover, operational runbooks, monitoring, security controls, and recovery procedures can meet the project's recovery objectives.

The target recovery objectives are:

- **Availability target:** 99.99%
- **Recovery Point Objective (RPO):** less than 1 minute
- **Recovery Time Objective (RTO):** less than 5 minutes
- **Primary region:** AWS Mumbai (`ap-south-1`)
- **DR region:** AWS Hyderabad (`ap-south-2`)

The annual program uses progressively more realistic exercises. Early exercises validate individual components and runbooks, while later exercises combine multiple failure conditions and include a controlled regional failover.

---

## 2. Scope

The DR drill program covers:

- EKS workloads and Kubernetes scheduling
- Application Load Balancers
- AWS WAF
- Aurora PostgreSQL
- DynamoDB
- ElastiCache Redis
- Amazon MSK
- Amazon S3
- Route 53 DNS failover
- Regional health checks
- KMS and Secrets Manager dependencies
- Transit Gateway and partner connectivity
- Monitoring and alerting
- Incident communication
- DR runbooks RB-01 through RB-12
- Data replication
- Data sovereignty controls
- Failback procedures
- Recovery validation
- Evidence collection and post-drill review

Production-impacting exercises require an approved change window and explicit authorization from the incident commander and business owner.

---

## 3. Roles and Responsibilities

| Role | Responsibility |
|---|---|
| Incident Commander | Owns the exercise, approves major decisions, and controls escalation |
| DR Lead | Coordinates recovery activities and validates the DR architecture |
| Platform/EKS Lead | Validates Kubernetes, compute, ingress, and service recovery |
| Database Lead | Validates Aurora and DynamoDB replication/recovery |
| Messaging Lead | Validates MSK replication, offsets, and consumer recovery |
| Network Lead | Validates DNS, networking, VPN, Transit Gateway, and connectivity |
| Security Lead | Validates security controls, KMS, credentials, and incident containment |
| Observability Lead | Validates CloudWatch, Prometheus, Grafana, logs, and alerting |
| Application Lead | Validates critical microservices and transaction processing |
| Compliance Lead | Validates PCI DSS, data sovereignty, evidence, and notification requirements |
| Business Owner | Confirms merchant and business impact is acceptable |
| Communications Lead | Coordinates internal, merchant, management, and external communications |
| Scribe | Records timestamps, commands, decisions, evidence, and issues |

---

## 4. Drill Classification

The program uses four exercise levels.

### Level 1 — Component Drill

Tests one infrastructure or application dependency.

Examples:

- EKS node failure
- Redis failure
- Kafka broker failure
- Certificate failure

### Level 2 — Service Recovery Drill

Tests recovery of a complete service or dependency chain.

Examples:

- Aurora recovery
- Kafka recovery
- DNS health-check failure
- application service cascade

### Level 3 — Regional DR Drill

Tests controlled traffic movement from Mumbai to Hyderabad.

This validates:

- DNS failover
- application capacity
- data replication
- service dependencies
- monitoring
- transaction validation
- RTO/RPO

### Level 4 — Full DR Exercise

Combines multiple failure scenarios and requires coordinated response from engineering, security, operations, compliance, and business teams.

---

# 5. Twelve-Month DR Calendar

## Month 1 — DR Readiness and Baseline Validation

**Exercise:** DR Readiness Review

**Type:** Tabletop / validation

**Objectives:**

1. Confirm all DR runbooks are present and current.
2. Verify ownership for RB-01 through RB-12.
3. Verify emergency contacts and escalation paths.
4. Confirm Mumbai and Hyderabad architecture documentation matches deployed configuration.
5. Verify monitoring dashboards and alerts.
6. Confirm replication monitoring is operational.
7. Verify required AWS permissions.

**Expected duration:** 2 hours

**Success criteria:**

- 100% of runbooks reviewed.
- All critical roles assigned.
- No unresolved P1 documentation gaps.
- Required dashboards and alerts confirmed operational.

---

## Month 2 — EKS and Application Recovery

**Exercise:** Kubernetes Worker/Pod Failure

**Type:** Level 1

**Related runbook:** RB-01 / application recovery procedures

**Objectives:**

- Simulate worker-node failure.
- Confirm Kubernetes reschedules workloads.
- Validate HPA behavior.
- Verify ALB target health.
- Confirm service-to-service communication.
- Confirm no unacceptable transaction loss.

**Expected duration:** 60–90 minutes

**Success criteria:**

- Critical pods recover automatically.
- Healthy ALB targets remain available.
- No persistent service outage.
- Application health checks remain successful.

---

## Month 3 — Database Recovery

**Exercise:** Aurora Regional Recovery

**Type:** Level 2

**Objectives:**

- Validate Aurora replication.
- Confirm replication lag monitoring.
- Validate controlled database promotion.
- Confirm application database connectivity.
- Test transaction reconciliation after recovery.

**Expected duration:** 2 hours

**Success criteria:**

- Replication remains within the defined RPO.
- Database promotion completes successfully.
- Application reconnects to the recovered database.
- Test transactions reconcile correctly.

---

## Month 4 — Messaging Recovery

**Exercise:** MSK Failure and Consumer Recovery

**Type:** Level 1/2

**Objectives:**

- Simulate broker failure.
- Validate Kafka cluster health.
- Verify consumer recovery.
- Confirm offsets are preserved.
- Validate transaction-event processing.
- Confirm duplicate handling and idempotency.

**Expected duration:** 90 minutes

**Success criteria:**

- Kafka remains available or recovers within the defined service objective.
- No unreconciled transaction-event loss.
- Consumer groups recover correctly.
- Duplicate messages do not create duplicate financial transactions.

---

## Month 5 — DNS and Traffic Failover

**Exercise:** Route 53 Health-Check Failure

**Type:** Level 2

**Objectives:**

- Simulate Mumbai endpoint health-check failure.
- Validate Route 53 failover behavior.
- Confirm Hyderabad becomes the active endpoint.
- Measure DNS detection and propagation timing.
- Validate client access after failover.

**Expected duration:** 90 minutes

**Success criteria:**

- Failed primary endpoint is detected.
- DNS failover occurs within the planned timing budget.
- Hyderabad accepts valid traffic.
- Critical application health checks pass.

---

## Month 6 — Security Recovery Exercise

**Exercise:** Cryptographic Key or Credential Compromise

**Type:** Level 2 / Security

**Related runbook:** RB-06

**Objectives:**

- Validate emergency credential/key rotation.
- Confirm affected credentials can be disabled.
- Verify replacement secrets are propagated.
- Confirm applications continue operating.
- Validate security logging and audit evidence.

**Expected duration:** 2 hours

**Success criteria:**

- Compromised credentials are isolated.
- Replacement credentials are deployed successfully.
- No unauthorized access remains.
- Required audit evidence is captured.

---

## Month 7 — Network Partition Exercise

**Exercise:** Mumbai Network Partition

**Type:** Level 2

**Related runbook:** RB-05

**Objectives:**

- Simulate loss of selected network connectivity.
- Validate service dependency behavior.
- Test partner connectivity monitoring.
- Confirm DNS and regional failover decision criteria.
- Validate split-brain prevention.

**Expected duration:** 2 hours

**Success criteria:**

- Network failure is detected.
- Critical dependencies are identified.
- No conflicting database writers are created.
- Recovery or failover decision is made within the defined escalation window.

---

## Month 8 — Data Sovereignty and Replication Validation

**Exercise:** Cross-Region Data Replication Review

**Type:** Level 2

**Objectives:**

- Verify replication paths.
- Confirm data classification.
- Validate encryption during replication.
- Verify KMS controls.
- Confirm data residency requirements.
- Validate retention and deletion controls.

**Expected duration:** 2 hours

**Success criteria:**

- All approved cross-region flows are documented.
- No unauthorized data path is detected.
- Encryption controls are verified.
- Compliance evidence is captured.

---

## Month 9 — Controlled Regional Failover

**Exercise:** Mumbai → Hyderabad DR Failover

**Type:** Level 3

**Objectives:**

- Execute a controlled regional failover.
- Validate DNS traffic movement.
- Promote the approved database target.
- Activate required Hyderabad application capacity.
- Validate Kafka and cache dependencies.
- Execute test transactions.
- Measure RTO and RPO.

**Expected duration:** 3 hours

**Success criteria:**

- RTO is less than 5 minutes for the critical failover path.
- RPO remains below 1 minute.
- Critical application endpoints are healthy.
- Test transactions complete successfully.
- No duplicate financial transactions occur.

---

## Month 10 — Failback Exercise

**Exercise:** Hyderabad → Mumbai Failback

**Type:** Level 3

**Objectives:**

- Restore Mumbai as the active region.
- Validate replication synchronization.
- Confirm controlled writer ownership.
- Move application traffic back to Mumbai.
- Validate post-failback reconciliation.

**Expected duration:** 3 hours

**Success criteria:**

- Mumbai is fully synchronized before becoming primary.
- Traffic returns without unacceptable interruption.
- Database writer ownership is correct.
- Test transactions reconcile successfully.

---

## Month 11 — Full Multi-Failure Exercise

**Exercise:** Cascading Failure + Regional Recovery

**Type:** Level 4

**Scenario:**

A simulated application failure occurs at the same time as degradation of a supporting infrastructure dependency.

The exercise tests whether the incident team can distinguish:

- application failure,
- infrastructure failure,
- data-layer failure,
- networking failure,
- regional failure.

**Objectives:**

1. Detect the initial failure.
2. Identify the failure domain.
3. Prevent unnecessary regional failover.
4. Execute the appropriate runbook.
5. Escalate when thresholds are exceeded.
6. Validate recovery.
7. Confirm transaction integrity.

**Expected duration:** 4 hours

**Success criteria:**

- Correct failure domain identified.
- Correct runbook selected.
- No unnecessary destructive action occurs.
- Recovery objectives are met.
- Complete incident timeline is captured.

---

## Month 12 — Annual Full DR Simulation

**Exercise:** Full Regional Disaster Recovery Drill

**Type:** Level 4

**Scenario:**

Simulated Mumbai regional outage requiring controlled recovery in Hyderabad.

The exercise combines:

- application availability failure,
- database failover,
- messaging recovery,
- DNS failover,
- network validation,
- security verification,
- monitoring,
- merchant communication,
- transaction validation,
- compliance evidence collection.

**Objectives:**

1. Execute the complete regional DR procedure.
2. Validate all critical runbooks.
3. Measure actual RTO.
4. Measure actual RPO.
5. Validate transaction integrity.
6. Validate merchant communication.
7. Validate compliance procedures.
8. Execute controlled failback.

**Expected duration:** 4–6 hours

**Success criteria:**

- Critical services recover within the target RTO.
- RPO remains below the target.
- No unreconciled financial transactions remain.
- DNS failover functions as designed.
- All critical dashboards remain available.
- Required communications are completed.
- Failback completes successfully.

---

# 6. Annual Testing Frequency

The program provides:

- **12 monthly exercises**
- **2 controlled regional exercises**
- **1 full annual regional simulation**
- Continuous monitoring of replication and health checks
- Additional drills after significant architectural changes

A production-impacting drill should not be performed without an approved change window.

---

# 7. Drill Preparation Checklist

Before each exercise:

- [ ] Define scenario and scope.
- [ ] Identify Incident Commander.
- [ ] Assign technical owners.
- [ ] Review affected runbook.
- [ ] Confirm monitoring dashboards.
- [ ] Confirm backup and replication health.
- [ ] Confirm rollback procedure.
- [ ] Confirm test transaction procedure.
- [ ] Notify required stakeholders.
- [ ] Establish start/end timestamps.
- [ ] Capture baseline metrics.
- [ ] Confirm abort criteria.
- [ ] Confirm AWS access and permissions.
- [ ] Confirm evidence collection location.

---

# 8. Drill Execution

During the exercise, the Scribe records:

- Detection timestamp
- Incident declaration timestamp
- Diagnostic timestamps
- Decision timestamps
- Failover initiation timestamp
- Database promotion timestamp
- DNS failover timestamp
- Application recovery timestamp
- First successful test transaction
- RTO
- Estimated RPO
- Failback timestamps
- Errors encountered
- Commands executed
- Dashboard evidence
- Communication timestamps

All times should use a consistent timezone and synchronized system clocks.

---

# 9. Abort Criteria

A drill must be stopped if:

1. Unexpected customer impact exceeds the approved scope.
2. Financial transaction integrity becomes uncertain.
3. An uncontrolled database writer or split-brain condition appears.
4. Security controls are unexpectedly bypassed.
5. Data sovereignty boundaries could be violated.
6. The Incident Commander determines that continued testing creates unacceptable operational risk.

When an abort condition occurs:

1. Stop the active test action.
2. Stabilize the affected system.
3. Restore the previous known-good state.
4. Verify application health.
5. Confirm transaction integrity.
6. Notify stakeholders.
7. Record the reason for the abort.

---

# 10. Post-Drill Process

Within 24 hours:

- Collect monitoring evidence.
- Export relevant logs.
- Record measured RTO/RPO.
- Compare actual results against targets.
- Document failed steps.
- Identify automation opportunities.
- Record configuration drift.
- Assign corrective actions.

Within 5 business days:

- Complete the post-drill review.
- Assign owners and deadlines.
- Update affected runbooks.
- Update architecture documentation.
- Update monitoring thresholds if required.
- Record lessons learned.

---

# 11. Annual Success Measures

The DR program is considered successful when:

| Metric | Target |
|---|---:|
| Critical DR tests completed | 100% |
| Critical runbook coverage | 100% |
| RTO for regional failover | < 5 minutes |
| RPO | < 1 minute |
| Critical test transaction success | 100% |
| Unreconciled financial transactions | 0 |
| Uncontrolled split-brain events | 0 |
| Critical unresolved drill findings | 0 before annual sign-off |
| Required evidence captured | 100% |
| Assigned corrective actions | 100% tracked |

---

# 12. Evidence Retention

Each drill should retain:

- Drill plan
- Approval/change record
- Participant list
- Timeline
- CloudWatch metrics
- Prometheus/Grafana screenshots or exports
- Relevant logs
- AWS CLI command outputs
- DNS resolution results
- Replication-lag evidence
- Test transaction IDs
- RTO/RPO calculations
- Communications
- Issues discovered
- Corrective action records
- Final post-drill report

Evidence should be stored according to PaySecure's retention and compliance requirements.

---

# 13. Annual Review

At the end of Month 12, the DR Lead and Incident Commander perform an annual program review.

The review must determine:

1. Whether the 99.99% availability objective remains appropriate.
2. Whether the RTO target remains achievable.
3. Whether the RPO target remains achievable.
4. Whether the DR architecture has changed.
5. Whether new AWS services or dependencies have been introduced.
6. Whether new compliance requirements apply.
7. Whether runbooks require revision.
8. Whether additional automation is required.
9. Whether DR capacity remains sufficient.
10. Whether the following year's drill calendar requires changes.

The annual review becomes the input for the next 12-month DR testing cycle.

---

## 14. Final Objective

The purpose of the annual DR drill program is not only to demonstrate that the architecture can fail over, but to continuously prove that people, processes, technology, monitoring, security controls, and data recovery procedures work together under realistic failure conditions.

A DR design is considered operationally ready only when its recovery procedures are repeatedly tested, measured, documented, and improved.