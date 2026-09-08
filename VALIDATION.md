# Validation Report

## Scope

This report records local validation completed for the PaySecure multi-region DR repository. No production AWS resources were accessed or modified.

## Results

| Area | Check | Result | Notes |
|---|---|---|---|
| Terraform | `terraform fmt -recursive` | PASS | Formatting applied to the Terraform files. |
| Terraform | `terraform init -backend=false -input=false` | PASS | Providers and modules initialized locally. |
| Terraform | `terraform validate` | PASS | Configuration is valid. A non-blocking DynamoDB `hash_key` deprecation warning remains. |
| Kubernetes | `kubectl kustomize configs/kubernetes` | PASS | Kustomization rendered successfully. |
| Kubernetes | `kubectl apply --dry-run=server -k configs/kubernetes` | PASS | Validated against a local Minikube Kubernetes API server. |
| Kubernetes | Apply to Minikube | PASS | Namespace, deployments, services, HPAs, PDBs, and NetworkPolicies were accepted. |
| PowerShell | Parser check for `scripts/**/*.ps1` | PASS | No parser errors found. |
| JSON | Parse `docs/04-dns-failover/route53-config.json` | PASS | JSON parsed successfully. |
| Failover scripts | Regional failover dry run | PASS | No AWS changes executed. |
| Failback scripts | Regional failback dry run | PASS | No AWS changes executed. |
| FMEA | 20 rows and RPN arithmetic | PASS | Every row satisfies `RPN = S x O x D`. |
| Markdown | Workspace diagnostics | PASS | No editor diagnostics reported for validated documents. |

## Kubernetes Test Environment

The manifests were tested on a disposable local Minikube cluster using Docker. Server-side schema validation passed. Pods did not become ready because the repository uses placeholder images and the local cluster was intentionally small; this is expected and is not a manifest schema failure. HPA metrics were unavailable because the local metrics API was not enabled.

## AWS Validation Boundary

Live AWS validation was not performed because no sandbox AWS account, credentials, or test resource identifiers were available. The following remain cloud-environment checks:

- Aurora Global Database promotion and switchover behavior
- Route 53 propagation and `INSYNC` timing
- EKS readiness using real application images
- MSK replication and replay
- Redis Global Datastore promotion
- DynamoDB replication and reconciliation
- S3 restore and cross-region replication
- End-to-end synthetic payment behavior

These checks must be performed only in a separately authorized sandbox account. The failover scripts require real resource identifiers and should never be executed with placeholder values.

## Reproduction Commands

```powershell
terraform -chdir=configs/terraform fmt -check -recursive
terraform -chdir=configs/terraform init -backend=false -input=false
terraform -chdir=configs/terraform validate

kubectl kustomize configs/kubernetes
kubectl apply --dry-run=server -k configs/kubernetes

Get-Content docs/04-dns-failover/route53-config.json -Raw | ConvertFrom-Json

$parseErrors = @()
Get-ChildItem scripts -Recurse -Filter *.ps1 | ForEach-Object {
  $null = [System.Management.Automation.Language.Parser]::ParseFile(
    $_.FullName, [ref]$null, [ref]$parseErrors
  )
}
if ($parseErrors.Count -gt 0) { throw ($parseErrors | Out-String) }

.\scripts\failover\regional-failover.ps1 `
  -GlobalClusterId 'paysecure-sandbox-global' `
  -DrDbClusterIdentifier 'paysecure-sandbox-dr'

.\scripts\failover\regional-failback.ps1 `
  -GlobalClusterId 'paysecure-sandbox-global' `
  -PrimaryDbClusterIdentifier 'paysecure-sandbox-primary'
```
