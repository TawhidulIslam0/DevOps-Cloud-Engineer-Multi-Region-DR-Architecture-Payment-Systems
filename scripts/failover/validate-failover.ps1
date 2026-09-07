[CmdletBinding()]
param(
    [string]$PrimaryRegion = "ap-south-1",
    [string]$DrRegion = "ap-south-2",

    [string]$PrimaryEndpoint = "",
    [string]$DrEndpoint = "",

    [string]$GlobalClusterId = "paysecure-global"
)

$ErrorActionPreference = "Continue"

$Results = @()

function Add-Result {
    param(
        [string]$Check,
        [string]$Status,
        [string]$Details
    )

    $script:Results += [PSCustomObject]@{
        Check   = $Check
        Status  = $Status
        Details = $Details
    }
}

Write-Host ""
Write-Host "=========================================="
Write-Host " PaySecure Failover Validation"
Write-Host "=========================================="
Write-Host ""

Write-Host "1. AWS identity"
try {
    aws sts get-caller-identity | Out-Null
    Add-Result "AWS identity" "PASS" "AWS CLI credentials are available."
}
catch {
    Add-Result "AWS identity" "FAIL" $_.Exception.Message
}

Write-Host "2. Primary region"
try {
    aws ec2 describe-availability-zones `
        --region $PrimaryRegion `
        --query "AvailabilityZones[].ZoneName" `
        --output text | Out-Null

    Add-Result "Primary region" "PASS" $PrimaryRegion
}
catch {
    Add-Result "Primary region" "FAIL" $_.Exception.Message
}

Write-Host "3. DR region"
try {
    aws ec2 describe-availability-zones `
        --region $DrRegion `
        --query "AvailabilityZones[].ZoneName" `
        --output text | Out-Null

    Add-Result "DR region" "PASS" $DrRegion
}
catch {
    Add-Result "DR region" "FAIL" $_.Exception.Message
}

Write-Host "4. Aurora global cluster"
try {
    $Aurora = aws rds describe-global-clusters `
        --global-cluster-identifier $GlobalClusterId `
        --output json

    Add-Result "Aurora global cluster" "PASS" "Global cluster query succeeded."
}
catch {
    Add-Result "Aurora global cluster" "FAIL" $_.Exception.Message
}

function Test-Api {
    param(
        [string]$Name,
        [string]$Endpoint
    )

    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        Add-Result $Name "SKIP" "Endpoint not configured."
        return
    }

    try {
        $Response = Invoke-WebRequest `
            -Uri $Endpoint `
            -Method Get `
            -TimeoutSec 10

        if ($Response.StatusCode -eq 200) {
            Add-Result $Name "PASS" "HTTP 200"
        }
        else {
            Add-Result $Name "FAIL" "HTTP $($Response.StatusCode)"
        }
    }
    catch {
        Add-Result $Name "FAIL" $_.Exception.Message
    }
}

Write-Host "5. Primary API"
Test-Api "Primary API" $PrimaryEndpoint

Write-Host "6. DR API"
Test-Api "DR API" $DrEndpoint

Write-Host "7. EKS"
try {
    aws eks list-clusters `
        --region $DrRegion `
        --output table

    Add-Result "DR EKS" "PASS" "EKS query succeeded."
}
catch {
    Add-Result "DR EKS" "FAIL" $_.Exception.Message
}

Write-Host "8. ALB"
try {
    aws elbv2 describe-load-balancers `
        --region $DrRegion `
        --query "LoadBalancers[].{Name:LoadBalancerName,State:State.Code}" `
        --output table

    Add-Result "DR ALB" "PASS" "ALB query succeeded."
}
catch {
    Add-Result "DR ALB" "FAIL" $_.Exception.Message
}

Write-Host "9. Route 53"
try {
    aws route53 list-health-checks --output json | Out-Null
    Add-Result "Route 53" "PASS" "Health checks query succeeded."
}
catch {
    Add-Result "Route 53" "FAIL" $_.Exception.Message
}

Write-Host ""
Write-Host "=========================================="
Write-Host " Validation Results"
Write-Host "=========================================="

$Results | Format-Table -AutoSize

$Failures = @($Results | Where-Object { $_.Status -eq "FAIL" })

if ($Failures.Count -gt 0) {
    Write-Host ""
    Write-Host "VALIDATION RESULT: FAIL"
    exit 1
}

Write-Host ""
Write-Host "VALIDATION RESULT: PASS"
exit 0