# DR Investment ROI Analysis

## 1. Executive Summary

This analysis evaluates the business return of investing in four disaster-recovery strategies:

1. Cold DR
2. Warm DR
3. Hot DR
4. Active-Active DR

The analysis compares the annual DR infrastructure investment against the financial exposure created by service downtime.

The project brief identifies:

- Current annual infrastructure spend: approximately **₹8 crore**
- Current uptime: approximately **99.92%**
- Current trailing downtime: approximately **7 hours**
- Target uptime: **99.99%**
- Target annual downtime budget: approximately **52.6 minutes**
- Direct revenue loss: approximately **₹37.5 lakh per hour**
- Recovery labor reference: **500+ engineer-hours at ₹3,000/hour**

The objective is not simply to select the least expensive DR architecture. The objective is to determine which DR investment provides an appropriate reduction in downtime risk for PaySecure's payment-processing workload.

---

# 2. Current Downtime Cost

The project brief provides an estimated direct revenue loss of approximately:

```text
₹37.5 lakh/hour