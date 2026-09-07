[CmdletBinding()]
param(
    [string[]]$Endpoints = @(
        "https://api.paysecure.example/health/ready"
    ),

    [int]$TimeoutSeconds = 10
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=========================================="
Write-Host " PaySecure Endpoint Health Check"
Write-Host "=========================================="
Write-Host ""

$Results = @()

foreach ($Endpoint in $Endpoints) {

    Write-Host "Checking: $Endpoint"

    try {
        $Start = Get-Date

        $Response = Invoke-WebRequest `
            -Uri $Endpoint `
            -Method Get `
            -TimeoutSec $TimeoutSeconds

        $Duration = ((Get-Date) - $Start).TotalMilliseconds

        $Status = if ($Response.StatusCode -eq 200) {
            "PASS"
        }
        else {
            "FAIL"
        }

        $Results += [PSCustomObject]@{
            Endpoint = $Endpoint
            Status   = $Status
            HTTP     = $Response.StatusCode
            LatencyMs = [math]::Round($Duration, 2)
        }
    }
    catch {
        $Results += [PSCustomObject]@{
            Endpoint = $Endpoint
            Status   = "FAIL"
            HTTP     = "N/A"
            LatencyMs = "N/A"
        }
    }
}

$Results | Format-Table -AutoSize

if (@($Results | Where-Object Status -eq "FAIL").Count -gt 0) {
    exit 1
}

exit 0