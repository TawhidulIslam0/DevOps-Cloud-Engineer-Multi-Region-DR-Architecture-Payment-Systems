# Error Hunter Analysis

## Purpose

The project brief asks the intern to identify five deliberate errors. The following five inconsistencies are present in the supplied training material and repository design. Each correction is reflected in the operational recommendations below.

## Error 1: Active-Active Aurora Is Described as Multi-Master

**Incorrect claim:** The active-active architecture describes Aurora Global Database as part of a multi-master or read-write target setup.

**Why it is wrong:** Standard Aurora Global Database has one write-primary Region and secondary Regions that are read-only until promotion. It is not a multi-master ledger database. Treating both Regions as ledger writers creates split-brain and transaction-ordering risk.

**Correction:** Keep Aurora ledger writes under explicit single-writer ownership. Use DynamoDB Global Tables only for state designed for multi-Region writes, such as idempotency metadata, with conditional writes and reconciliation. The failover runbooks must verify exactly one Aurora writer before opening payment traffic.

**Affected deliverables:** Active-active design, replication strategy, RB-01, RB-02, RB-05.

## Error 2: Active-Passive RTO and RPO Contradict the Project Targets

**Incorrect claim:** The active-passive comparison gives approximately 15 minutes RTO and up to 5 minutes RPO while the project objectives require RTO below 5 minutes and RPO below 1 minute.

**Why it is wrong:** A design that is explicitly documented at 15 minutes and 5 minutes cannot claim compliance with the stricter project target without additional capacity, automation, and replication evidence.

**Correction:** Treat the 15-minute/5-minute figures as a non-compliant baseline. The proposed hot-standby design must provide a summed failover budget under 5 minutes and promotion gates that reject replication lag over 60 seconds. If that cannot be demonstrated, state the target as unmet rather than claiming compliance.

**Affected deliverables:** Active-passive design, comparison matrix, timing diagram, RB-01.

## Error 3: DNS TTL Is Treated as a Guaranteed Cutover Time

**Incorrect claim:** A 60-second Route 53 TTL is treated as proof that every client moves to the new Region within 60 seconds.

**Why it is wrong:** TTL controls resolver caching, but existing TCP connections, application connection pools, stale recursive caches, and client retry behavior can extend the real traffic transition. DNS health detection and Route 53 change propagation add separate delays.

**Correction:** Budget detection, decision, Route 53 INSYNC, resolver convergence, connection draining, and retry stabilization separately. Verify DNS from independent resolvers and use Global Accelerator or explicit connection draining when a bounded transition is required.

**Affected deliverables:** DNS design, timing diagram, RB-01, synthetic monitoring specification.

## Error 4: S3 CRR Is Assumed to Meet a Sub-Minute Transaction RPO

**Incorrect claim:** S3 Cross-Region Replication is treated as sufficient for the same sub-minute RPO as the financial ledger.

**Why it is wrong:** S3 replication is asynchronous and object replication can take minutes. S3 is not a transaction commit protocol and should not be used to guarantee ledger or payment-event RPO.

**Correction:** Classify S3 objects by recovery objective. Keep financial transaction state in Aurora/DynamoDB/event systems with their own lag gates. Use S3 CRR for artifacts, audit objects, and backups, and measure replication status separately. A restore test must prove the actual S3 recovery point.

**Affected deliverables:** Replication strategy, data sovereignty, cost analysis, DR drill plan.

## Error 5: Synchronous Cross-Region Replication Is Claimed to Be Free of Latency Impact

**Incorrect claim:** A 15-25 ms Mumbai-Hyderabad round trip is presented as if synchronous replication can be added without materially changing the 180 ms P99 transaction latency.

**Why it is wrong:** The network RTT is only one part of the synchronous commit cost. Serialization, remote commit, acknowledgement, retries, queueing, and peak settlement IOPS add overhead. The 120 ms remaining budget (`300 - 180`) is not automatically available for replication alone.

**Correction:** Measure the full added commit latency under peak load and reserve an explicit budget for database and application processing. Use synchronous protection only where the measured P99 remains below 300 ms; use asynchronous replication for components where the latency or availability trade-off is unacceptable, with an explicit RPO gate.

**Affected deliverables:** Replication strategy, active-active design, latency analysis, monitoring thresholds.

## Verification Checklist

- [ ] Aurora design names one writer and a tested promotion target.
- [ ] Active-passive RTO/RPO claims are reconciled with the project objectives.
- [ ] Timing diagram includes DNS detection, propagation, connection draining, and retry stabilization.
- [ ] S3 is assigned a separate object-recovery objective rather than ledger RPO.
- [ ] Peak-load measurements demonstrate the latency effect of synchronous replication.
- [ ] Corrections are referenced by the relevant runbooks and drill success criteria.
