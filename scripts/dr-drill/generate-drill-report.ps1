[CmdletBinding()]
param(
    [string]$EvidenceDirectory = "drill-evidence",

    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $EvidenceDirectory)) {
    throw "Evidence directory does not exist: $EvidenceDirectory"
}

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    $OutputFile = Join-Path `
        $EvidenceDirectory `
        "dr-drill-report-$Timestamp.md"
}

$Files = Get-ChildItem `
    -Path $EvidenceDirectory `
    -Recurse `
    -File

$FileList = $Files |
    ForEach-Object {
        "- $($_.FullName)"
    }

$Report = @"
# PaySecure DR Drill Report

## Drill Identification

| Field | Value |
|---|---|
| Drill Date | $(Get-Date -Format "yyyy-MM-dd") |
| Report Generated | $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") |
| Evidence Directory | $EvidenceDirectory |
| Total Evidence Files | $($Files.Count) |

---

## Executive Summary

**Overall Result:** [PASS / CONDITIONAL PASS / FAIL]

**Scenario Tested:** [Regional Failover / Failback / Other]

**Primary Region:** ap-south-1

**DR Region:** ap-south-2

---

## RTO Measurement

**Target:** < 5 minutes

**Measured:** [INSERT]

**Result:** [PASS / FAIL]

---

## RPO Measurement

**Target:** < 1 minute

**Measured:** [INSERT]

**Result:** [PASS / FAIL]

---

## Application Validation

- [ ] API health endpoint returned HTTP 200
- [ ] Critical services available
- [ ] Test transaction completed
- [ ] Transaction status verified
- [ ] No duplicate transaction created
- [ ] Merchant-facing functionality verified

---

## Infrastructure Validation

- [ ] EKS nodes healthy
- [ ] Critical pods available
- [ ] HPA operating normally
- [ ] PDBs present
- [ ] ALB healthy
- [ ] Aurora healthy
- [ ] DynamoDB replication healthy
- [ ] MSK healthy
- [ ] ElastiCache healthy
- [ ] S3 replication verified

---

## DNS Validation

- [ ] Route 53 health checks healthy
- [ ] DNS resolved to expected endpoint
- [ ] TTL behavior verified
- [ ] No stale routing observed

---

## Security Validation

- [ ] TLS certificate valid
- [ ] KMS access validated
- [ ] Secrets access validated
- [ ] CloudTrail events captured
- [ ] No unauthorized access observed

---

## Data Integrity

- [ ] Transaction counts reconciled
- [ ] No unexpected duplicates
- [ ] No missing critical transactions
- [ ] Kafka offsets validated
- [ ] Database consistency validated

---

## Monitoring

- [ ] CloudWatch alarms reviewed
- [ ] Prometheus alerts reviewed
- [ ] Grafana dashboards reviewed
- [ ] Logs collected
- [ ] Traces reviewed where applicable
- [ ] PagerDuty notifications validated

---

## Communications

| Audience | Notification Time | Owner | Status |
|---|---|---|---|
| Engineering | [TIME] | [NAME] | [PASS/FAIL] |
| Management | [TIME] | [NAME] | [PASS/FAIL] |
| Merchants | [TIME] | [NAME] | [PASS/FAIL] |
| Regulators | [TIME] | [NAME] | [PASS/FAIL] |

---

## Failback

- [ ] Primary region restored
- [ ] Replication caught up
- [ ] Controlled switchover completed
- [ ] DNS returned to primary
- [ ] Application validated
- [ ] Data reconciliation completed

---

## Findings

### What Worked

- [ITEM]

### What Failed

- [ITEM]

### Unexpected Behavior

- [ITEM]

---

## Root Cause / Contributing Factors

[INSERT RCA]

---

## Corrective Actions

| ID | Finding | Action | Owner | Priority | Due Date |
|---|---|---|---|---|---|
| CA-001 | [Finding] | [Action] | [Owner] | P1/P2/P3 | [Date] |
| CA-002 | [Finding] | [Action] | [Owner] | P1/P2/P3 | [Date] |

---

## Evidence Files

$($FileList -join "`n")

---

## Final Assessment

**RTO:** [PASS / FAIL]

**RPO:** [PASS / FAIL]

**Application:** [PASS / FAIL]

**Data Integrity:** [PASS / FAIL]

**Security:** [PASS / FAIL]

**Monitoring:** [PASS / FAIL]

**Communication:** [PASS / FAIL]

**Failback:** [PASS / FAIL]

### Overall Drill Result

**[PASS / CONDITIONAL PASS / FAIL]**

---

## Approval

| Role | Name | Decision | Date |
|---|---|---|---|
| Incident Commander | [NAME] | [APPROVE] | [DATE] |
| Engineering Lead | [NAME] | [APPROVE] | [DATE] |
| Security Lead | [NAME] | [APPROVE] | [DATE] |
| Compliance Lead | [NAME] | [APPROVE] | [DATE] |
"@

$Report | Out-File `
    -FilePath $OutputFile `
    -Encoding utf8

Write-Host ""
Write-Host "=========================================="
Write-Host " DR Drill Report Generated"
Write-Host "=========================================="
Write-Host ""
Write-Host "Report:"
Write-Host $OutputFile