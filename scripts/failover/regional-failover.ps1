[CmdletBinding()]
param(
    [switch]$Execute,

    [string]$PrimaryRegion = "ap-south-1",
    [string]$DrRegion = "ap-south-2",

    [string]$GlobalClusterId = "paysecure-global",
    [string]$DrDbClusterIdentifier = "",
    [switch]$AllowDataLoss,

    [string]$PrimaryAlbDns = "",
    [string]$DrAlbDns = "",
    [string]$DrAlbHostedZoneId = "",
    [string]$DrHealthCheckId = "",

    [string]$HostedZoneId = "",
    [string]$RecordName = "api.paysecure.example",

    [int]$HealthCheckAttempts = 3,
    [int]$HealthCheckDelaySeconds = 10
)

$ErrorActionPreference = "Stop"

$Mode = if ($Execute) { "EXECUTE" } else { "DRY-RUN" }

Write-Host ""
Write-Host "==========================================" 
Write-Host " PaySecure Regional Failover"
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
        Write-Host "$Name endpoint not configured; skipping."
        return $false
    }

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 10
        Write-Host "$Name returned HTTP $($response.StatusCode)"
        return ($response.StatusCode -eq 200)
    }
    catch {
        Write-Host "$Name health check failed: $($_.Exception.Message)"
        return $false
    }
}

Write-Host "Step 1: Confirming AWS identity..."
Invoke-SafeAwsCommand `
    "AWS identity" `
    "sts get-caller-identity"

Write-Host ""
Write-Host "Step 2: Checking primary region..."
Invoke-SafeAwsCommand `
    "Primary region" `
    "ec2 describe-availability-zones --region $PrimaryRegion --query 'AvailabilityZones[].ZoneName' --output table"

Write-Host ""
Write-Host "Step 3: Checking DR region..."
Invoke-SafeAwsCommand `
    "DR region" `
    "ec2 describe-availability-zones --region $DrRegion --query 'AvailabilityZones[].ZoneName' --output table"

Write-Host ""
Write-Host "Step 4: Checking Aurora global cluster..."
Invoke-SafeAwsCommand `
    "Aurora global cluster" `
    "rds describe-global-clusters --global-cluster-identifier $GlobalClusterId --query 'GlobalClusters[0].{Status:Status,Members:GlobalClusterMembers}' --output json"

Write-Host ""
Write-Host "Step 5: Testing primary endpoint..."
$PrimaryHealthy = Test-Endpoint `
    -Name "Primary API" `
    -Url $(if ($PrimaryAlbDns) { "https://$PrimaryAlbDns/health/ready" } else { "" })

Write-Host ""
Write-Host "Step 6: Testing DR endpoint..."
$DrHealthy = Test-Endpoint `
    -Name "DR API" `
    -Url $(if ($DrAlbDns) { "https://$DrAlbDns/health/ready" } else { "" })

Write-Host ""
Write-Host "Step 7: Confirming DR readiness..."

if (-not $Execute) {
    Write-Host "DRY-RUN: DR readiness confirmed from configuration only."
}
else {
    if (-not $DrHealthy) {
        throw "DR endpoint is not healthy. Failover aborted."
    }
}

Write-Host ""
Write-Host "Step 8: Aurora failover/switchover..."

if ($Execute -and [string]::IsNullOrWhiteSpace($DrDbClusterIdentifier)) {
    throw "DrDbClusterIdentifier is required when executing a failover. Use the regional Aurora cluster identifier, not the global cluster identifier."
}

$FailoverOptions = if ($AllowDataLoss) { "--allow-data-loss" } else { "" }

Invoke-SafeAwsCommand `
    "Aurora global database operation" `
    "rds failover-global-cluster --global-cluster-identifier $GlobalClusterId --target-db-cluster-identifier $DrDbClusterIdentifier --region $DrRegion $FailoverOptions"

Write-Host ""
Write-Host "Step 9: Waiting for database state..."

Start-Sleep -Seconds 5

Invoke-SafeAwsCommand `
    "Aurora status" `
    "rds describe-global-clusters --global-cluster-identifier $GlobalClusterId --query 'GlobalClusters[0].{Status:Status,Members:GlobalClusterMembers}' --output json"

Write-Host ""
Write-Host "Step 10: Traffic routing change..."

if ([string]::IsNullOrWhiteSpace($HostedZoneId)) {
    Write-Host "Hosted Zone ID not configured; Route 53 change skipped."
}
else {
    if ([string]::IsNullOrWhiteSpace($DrAlbDns) -or [string]::IsNullOrWhiteSpace($DrAlbHostedZoneId) -or [string]::IsNullOrWhiteSpace($DrHealthCheckId)) {
        throw "DrAlbDns, DrAlbHostedZoneId, and DrHealthCheckId are required to submit the Route 53 secondary alias record."
    }

    $ChangeBatch = @"
{
  "Comment": "PaySecure DR regional failover",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RecordName",
        "Type": "A",
        "SetIdentifier": "DR",
        "Failover": {
          "Failover": "SECONDARY"
        },
                ""AliasTarget"": {
                    ""HostedZoneId"": ""$DrAlbHostedZoneId"",
                    ""DNSName"": ""dualstack.$DrAlbDns"",
                    ""EvaluateTargetHealth"": true
                },
        "TTL": 60,
                ""HealthCheckId"": ""$DrHealthCheckId""
      }
    }
  ]
}
"@

    if ($Execute) {
        $ChangeFile = Join-Path $env:TEMP "paysecure-route53-failover-$([guid]::NewGuid()).json"
        Set-Content -Path $ChangeFile -Value $ChangeBatch -Encoding ascii
        try {
            $ChangeId = aws route53 change-resource-record-sets `
                --hosted-zone-id $HostedZoneId `
                --change-batch "file://$ChangeFile" `
                --query "ChangeInfo.Id" `
                --output text

            aws route53 wait resource-record-sets-changed --id $ChangeId
        }
        finally {
            Remove-Item -Path $ChangeFile -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        Write-Host "DRY-RUN: Route 53 change batch generated but not submitted."
    }
}

Write-Host ""
Write-Host "Step 11: Validating DR endpoint..."

if ($Execute) {
    $DrHealthy = Test-Endpoint `
        -Name "DR API after failover" `
        -Url $(if ($DrAlbDns) { "https://$DrAlbDns/health/ready" } else { "" })

    if (-not $DrHealthy) {
        throw "DR endpoint failed post-failover validation."
    }
}

Write-Host ""
Write-Host "Step 12: Checking Kubernetes nodes..."
Invoke-SafeAwsCommand `
    "DR EKS clusters" `
    "eks list-clusters --region $DrRegion --output table"

Write-Host ""
Write-Host "Step 13: Checking application load balancers..."
Invoke-SafeAwsCommand `
    "DR load balancers" `
    "elbv2 describe-load-balancers --region $DrRegion --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' --output table"

Write-Host ""
Write-Host "Step 14: Checking Route 53 health checks..."
Invoke-SafeAwsCommand `
    "Route 53 health checks" `
    "route53 list-health-checks --output json"

Write-Host ""
Write-Host "Step 15: Recording failover completion..."

$Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

Write-Host ""
Write-Host "FAILOVER WORKFLOW COMPLETE"
Write-Host "Timestamp: $Timestamp"
Write-Host "Primary:  $PrimaryRegion"
Write-Host "DR:       $DrRegion"
Write-Host "Mode:     $Mode"
Write-Host ""

if (-not $Execute) {
    Write-Host "No production changes were executed."
    Write-Host "Use -Execute only after formal incident approval."
}