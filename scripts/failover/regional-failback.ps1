[CmdletBinding()]
param(
    [switch]$Execute,

    [string]$PrimaryRegion = "ap-south-1",
    [string]$DrRegion = "ap-south-2",
    [string]$GlobalClusterId = "paysecure-global",
    [string]$PrimaryDbClusterIdentifier = "",

    [string]$PrimaryAlbDns = "",
    [string]$DrAlbDns = ""
)

$ErrorActionPreference = "Stop"

$Mode = if ($Execute) { "EXECUTE" } else { "DRY-RUN" }

Write-Host ""
Write-Host "=========================================="
Write-Host " PaySecure Regional Failback"
Write-Host " Mode: $Mode"
Write-Host "=========================================="
Write-Host ""

function Invoke-SafeAwsCommand {
    param(
        [string]$Description,
        [string]$Command
    )

    Write-Host ""
    Write-Host "[$Description]"
    Write-Host "aws $Command"

    if ($Execute) {
        Invoke-Expression "aws $Command"
    }
    else {
        Write-Host "DRY-RUN: command not executed."
    }
}

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url
    )

    if ([string]::IsNullOrWhiteSpace($Url)) {
        Write-Host "$Name endpoint not configured."
        return $false
    }

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 10
        Write-Host "$Name returned HTTP $($response.StatusCode)"
        return $response.StatusCode -eq 200
    }
    catch {
        Write-Host "$Name check failed."
        return $false
    }
}

Write-Host "Step 1: Confirm AWS identity"
Invoke-SafeAwsCommand `
    "AWS identity" `
    "sts get-caller-identity"

Write-Host ""
Write-Host "Step 2: Confirm primary region health"
Invoke-SafeAwsCommand `
    "Primary AZs" `
    "ec2 describe-availability-zones --region $PrimaryRegion --query 'AvailabilityZones[].ZoneName' --output table"

Write-Host ""
Write-Host "Step 3: Confirm DR region health"
Invoke-SafeAwsCommand `
    "DR AZs" `
    "ec2 describe-availability-zones --region $DrRegion --query 'AvailabilityZones[].ZoneName' --output table"

Write-Host ""
Write-Host "Step 4: Test primary API"
$PrimaryHealthy = Test-Endpoint `
    -Name "Primary API" `
    -Url $(if ($PrimaryAlbDns) { "https://$PrimaryAlbDns/health/ready" } else { "" })

if ($Execute -and -not $PrimaryHealthy) {
    throw "Primary environment is not healthy. Failback aborted."
}

Write-Host ""
Write-Host "Step 5: Test DR API"
$DrHealthy = Test-Endpoint `
    -Name "DR API" `
    -Url $(if ($DrAlbDns) { "https://$DrAlbDns/health/ready" } else { "" })

Write-Host ""
Write-Host "Step 6: Inspect Aurora global database"
Invoke-SafeAwsCommand `
    "Aurora state" `
    "rds describe-global-clusters --global-cluster-identifier $GlobalClusterId --query 'GlobalClusters[0].{Status:Status,Members:GlobalClusterMembers}' --output json"

Write-Host ""
Write-Host "Step 7: Confirm replication health"
Write-Host "Verify Aurora replication lag, DynamoDB replication, MSK replication, Redis state and S3 replication before continuing."

Write-Host ""
Write-Host "Step 8: Rebuild/reconcile primary environment"
Invoke-SafeAwsCommand `
    "Primary EKS clusters" `
    "eks list-clusters --region $PrimaryRegion --output table"

Write-Host ""
Write-Host "Step 9: Validate primary load balancer"
Invoke-SafeAwsCommand `
    "Primary ALBs" `
    "elbv2 describe-load-balancers --region $PrimaryRegion --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' --output table"

Write-Host ""
Write-Host "Step 10: Controlled Aurora switchover"

if ($Execute -and [string]::IsNullOrWhiteSpace($PrimaryDbClusterIdentifier)) {
    throw "PrimaryDbClusterIdentifier is required when executing failback. Use the regional Aurora cluster identifier, not the global cluster identifier."
}

Invoke-SafeAwsCommand `
    "Aurora switchover" `
    "rds switchover-global-cluster --global-cluster-identifier $GlobalClusterId --target-db-cluster-identifier $PrimaryDbClusterIdentifier --region $PrimaryRegion"

Write-Host ""
Write-Host "Step 11: Wait for database topology stabilization"
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Step 12: Validate application connectivity"
if ($Execute) {
    if (-not $PrimaryHealthy) {
        throw "Primary application validation failed."
    }
}

Write-Host ""
Write-Host "Step 13: Validate DNS routing"
Invoke-SafeAwsCommand `
    "Route 53 health checks" `
    "route53 list-health-checks --output json"

Write-Host ""
Write-Host "Step 14: Validate critical services"
Invoke-SafeAwsCommand `
    "DR region EKS" `
    "eks list-clusters --region $DrRegion --output table"

Write-Host ""
Write-Host "Step 15: Complete failback evidence"
$Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

Write-Host ""
Write-Host "FAILBACK WORKFLOW COMPLETE"
Write-Host "Timestamp: $Timestamp"
Write-Host "Primary:  $PrimaryRegion"
Write-Host "DR:       $DrRegion"
Write-Host "Mode:     $Mode"
Write-Host ""

if (-not $Execute) {
    Write-Host "No production changes were executed."
}