# DR Cost Summary

## 1. Executive Summary

This cost analysis compares four disaster-recovery strategies for PaySecure:

1. **Cold DR**
2. **Warm DR**
3. **Hot DR**
4. **Active-Active DR**

The comparison evaluates infrastructure investment, recovery objectives, downtime exposure, operational complexity, and business impact.

The project brief identifies a current annual infrastructure spend of approximately **₹8 crore**, current uptime of **99.92%**, and approximately **7 hours of downtime during the trailing 12-month period**. The target state is **99.99% availability**, corresponding to a maximum annual downtime budget of approximately **52.6 minutes**.

The project brief also provides an estimated direct revenue impact of approximately **₹37.5 lakh per hour** of downtime. :contentReference[oaicite:2]{index=2}

The cost model therefore evaluates both:

- direct infrastructure cost, and
- the economic impact of downtime.

The spreadsheet contains a line-item model covering 19 AWS service categories across all four DR tiers.

---

## 2. Pricing Methodology

The model uses a combination of:

- AWS published pricing information
- project-specific architecture quantities
- DR capacity assumptions
- editable planning rates
- cross-region replication requirements
- backup and recovery requirements

AWS pricing is usage based for many of the services used by the architecture.

For example:

- Amazon EKS charges a cluster-hour fee.
- Route 53 charges for hosted zones, DNS queries, and applicable health checks.
- NAT Gateway charges are based on gateway-hours and data processed.
- Amazon MSK charges for broker usage and storage.
- Amazon S3 pricing includes storage, requests, transfer, and replication.
- ElastiCache pricing depends on node/serverless usage, backups, data transfer, and replication.

The model intentionally keeps service rates editable so that verified AWS Pricing Calculator results can replace planning assumptions before final submission.

---

# 3. AWS Service Categories

The cost model includes the following categories:

| # | AWS Service Category |
|---:|---|
| 1 | Amazon EKS |
| 2 | EC2 worker nodes |
| 3 | EBS |
| 4 | Application Load Balancer |
| 5 | AWS WAF |
| 6 | Aurora PostgreSQL |
| 7 | DynamoDB |
| 8 | ElastiCache Redis |
| 9 | Amazon MSK |
| 10 | Amazon S3 |
| 11 | AWS KMS |
| 12 | AWS Secrets Manager |
| 13 | Amazon Route 53 |
| 14 | NAT Gateway |
| 15 | Amazon CloudWatch |
| 16 | VPC PrivateLink endpoints |
| 17 | AWS Transit Gateway |
| 18 | Cross-region data transfer |
| 19 | Backup and snapshots |

This exceeds the project's requirement for 15+ AWS service categories. :contentReference[oaicite:3]{index=3}

---

# 4. DR Tier Comparison

## 4.1 Cold DR

Cold DR maintains the smallest amount of continuously running secondary infrastructure.

### Characteristics

- Minimal standby compute
- Backups and snapshots are the primary recovery mechanism
- Infrastructure is provisioned or scaled during an incident
- Lowest ongoing infrastructure cost
- Longest recovery time
- Highest operational dependency on restoration procedures

### Target Planning Profile

| Metric | Cold DR |
|---|---:|
| Target RTO | ~4 hours |
| Target RPO | ~1 hour |
| Standby capacity | ~10% |
| Relative infrastructure cost | Lowest |

Cold DR is appropriate for workloads where extended downtime is financially acceptable.

For PaySecure's payment-processing workload, however, the recovery time is significantly less aligned with the project's <5-minute RTO objective.

---

# 5. Warm DR

Warm DR maintains a partially provisioned secondary environment.

### Characteristics

- Standby EKS capacity
- Replicated databases
- Replicated object storage
- Cross-region replication
- Reduced recovery provisioning time
- Lower cost than Hot or Active-Active DR

### Target Planning Profile

| Metric | Warm DR |
|---|---:|
| Target RTO | ~30 minutes |
| Target RPO | ~5 minutes |
| Standby capacity | ~35% |
| Relative infrastructure cost | Medium |

Warm DR provides a significant improvement over Cold DR but does not naturally meet the project's <5-minute RTO and <1-minute RPO targets without additional optimization.

---

# 6. Hot DR

Hot DR maintains a highly prepared secondary region.

### Characteristics

- Significant pre-provisioned compute
- Continuously replicated data
- Rapid application startup
- Preconfigured networking
- Preconfigured monitoring
- Faster database promotion
- Rapid DNS failover

### Target Planning Profile

| Metric | Hot DR |
|---|---:|
| Target RTO | ~10 minutes |
| Target RPO | ~1 minute |
| Standby capacity | ~70% |
| Relative infrastructure cost | High |

Hot DR provides a strong balance between recovery performance and infrastructure cost.

However, the planning RTO of approximately 10 minutes remains above the project's formal <5-minute RTO objective.

---

# 7. Active-Active DR

Active-Active operates both regions as production-capable environments.

### Characteristics

- Both regions actively serve traffic
- Full application capacity in both regions
- Cross-region data replication
- DNS-based traffic management
- Continuous health monitoring
- Reduced recovery dependency on provisioning
- Highest infrastructure and operational complexity

### Target Planning Profile

| Metric | Active-Active |
|---|---:|
| Target RTO | ~1 minute |
| Target RPO | Seconds |
| Standby capacity | 100% |
| Relative infrastructure cost | Highest |

Active-Active is the architecture most closely aligned with the project's availability and recovery objectives.

---

# 8. Planning Cost Comparison

The current working spreadsheet produces the following planning-level estimates using the editable assumptions contained in `cost-model.xlsx`.

| DR Tier | Approx. Monthly USD | Approx. Annual INR* |
|---|---:|---:|
| Cold | $746/month | ₹46.3 lakh/year |
| Warm | $1,618/month | ₹1.00 crore/year |
| Hot | $2,844/month | ₹1.76 crore/year |
| Active-Active | $3,950/month | ₹2.45 crore/year |

\*Uses the spreadsheet's editable planning FX assumption of ₹85/USD.

> These are **planning estimates**, not final AWS quotes. The rates for individual services should be replaced with verified `ap-south-1` and `ap-south-2` AWS Pricing Calculator values before the final submission.

---

# 9. Cost Drivers

The largest cost drivers are expected to be:

### 1. Compute

EKS worker capacity represents a major portion of the DR environment because the production architecture contains approximately 24 worker nodes.

Cold and Warm tiers reduce the amount of continuously running secondary capacity.

Hot and Active-Active retain substantially more capacity.

### 2. Aurora PostgreSQL

Aurora is a critical cost component because the database must support:

- replication
- recovery
- read/write capacity
- storage
- backups
- cross-region operation

### 3. DynamoDB

DynamoDB capacity and multi-region replication increase cost as the DR strategy moves toward Active-Active operation.

### 4. ElastiCache

Redis capacity must be available in the recovery region to avoid turning a cache failure into a database overload event.

### 5. MSK

The production environment uses six Kafka brokers with approximately 50,000 messages/second peak throughput.

Cross-region replication and additional broker capacity increase the DR cost.

### 6. Cross-Region Data Transfer

Active-Active has the largest cross-region data-transfer requirement because replication is continuous and both regions actively participate in production.

---

# 10. Cost Optimization Opportunities

The following controls should be considered before production implementation:

## Compute

- Right-size EC2 worker nodes
- Use autoscaling
- Use Savings Plans where workload stability justifies commitment
- Avoid running 100% standby capacity unless RTO requirements justify it

## EKS

- Maintain only the required standby node capacity
- Scale the DR environment automatically
- Avoid unnecessary always-on worker capacity

## Storage

- Apply appropriate S3 storage classes
- Lifecycle old backups
- Compress archived data
- Delete expired snapshots according to retention policies

## Network

- Use VPC endpoints for AWS services where appropriate
- Avoid unnecessary cross-AZ traffic
- Place NAT gateways strategically
- Monitor cross-region transfer volume

AWS specifically recommends evaluating endpoint usage and NAT Gateway placement because NAT Gateway costs include both availability-hour and data-processing charges. :contentReference[oaicite:4]{index=4}

## ElastiCache

Evaluate node sizing, serverless options, backup retention, and cross-region replication requirements. AWS states that ElastiCache pricing varies with deployment type, node usage, backups, data transfer, and cross-region replication. :contentReference[oaicite:5]{index=5}

## MSK

Review:

- broker sizing
- storage allocation
- retention period
- replication volume
- cross-region data transfer

MSK provisioned clusters incur broker and storage charges, with additional costs possible for data transfer and related features. :contentReference[oaicite:6]{index=6}

---

# 11. Business Trade-Off

The DR tiers can be summarized as:

| Tier | Cost | Recovery | Complexity | PaySecure Fit |
|---|---|---|---|---|
| Cold | Lowest | Slow | Low | Poor |
| Warm | Low/Medium | Moderate | Medium | Limited |
| Hot | High | Fast | High | Strong |
| Active-Active | Highest | Fastest | Very High | Best |

PaySecure processes payment transactions, making prolonged downtime financially and operationally significant.

The architecture therefore favors **Hot or Active-Active DR**, with Active-Active providing the strongest alignment with the project's <5-minute RTO and <1-minute RPO objectives.

---

# 12. Recommendation

### Recommended Target: Active-Active

Active-Active provides the strongest technical alignment with the project's recovery objectives because:

1. Both regions remain production capable.
2. Application capacity does not need to be created from zero during an incident.
3. DNS can redirect traffic rapidly.
4. Data replication is continuously maintained.
5. Regional recovery can occur with minimal provisioning.
6. It minimizes customer-facing downtime.

### Cost-Controlled Alternative: Hot DR

If the full Active-Active investment cannot be justified, Hot DR is the preferred intermediate architecture.

Hot DR maintains substantial standby capacity while avoiding the full cost of two simultaneously active production environments.

---

# 13. Important Cost-Model Limitation

The current spreadsheet should be treated as a **planning model**.

Several AWS services have pricing dimensions that cannot be represented accurately by a single flat monthly rate.

Examples include:

- requests
- data transfer
- storage volume
- broker hours
- API calls
- health checks
- NAT data processing
- database I/O
- replication volume

Therefore, before final submission, the editable planning rates should be replaced with validated AWS Pricing Calculator outputs for both:

```text
ap-south-1 — Mumbai
ap-south-2 — Hyderabad