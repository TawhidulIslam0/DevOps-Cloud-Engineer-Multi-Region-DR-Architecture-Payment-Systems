[CmdletBinding()]
param(
    [string]$RecordName = "api.paysecure.example",

    [string]$ExpectedPrimary = "",

    [string]$ExpectedDr = ""
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=========================================="
Write-Host " PaySecure DNS Health Check"
Write-Host "=========================================="
Write-Host ""

Write-Host "Resolving: $RecordName"

try {
    $Records = Resolve-DnsName `
        -Name $RecordName `
        -Type A `
        -ErrorAction Stop

    $Addresses = @(
        $Records |
        Where-Object { $_.Type -eq "A" } |
        Select-Object -ExpandProperty IPAddress
    )

    Write-Host ""
    Write-Host "Resolved IP addresses:"
    $Addresses | ForEach-Object {
        Write-Host " - $_"
    }

    if ($ExpectedPrimary -and $Addresses -contains $ExpectedPrimary) {
        Write-Host ""
        Write-Host "DNS validation: PRIMARY target detected."
        exit 0
    }

    if ($ExpectedDr -and $Addresses -contains $ExpectedDr) {
        Write-Host ""
        Write-Host "DNS validation: DR target detected."
        exit 0
    }

    if (-not $ExpectedPrimary -and -not $ExpectedDr) {
        Write-Host ""
        Write-Host "DNS resolution succeeded."
        exit 0
    }

    Write-Host ""
    Write-Host "DNS validation: EXPECTED TARGET NOT FOUND."
    exit 1
}
catch {
    Write-Host ""
    Write-Host "DNS resolution failed:"
    Write-Host $_.Exception.Message
    exit 1
}