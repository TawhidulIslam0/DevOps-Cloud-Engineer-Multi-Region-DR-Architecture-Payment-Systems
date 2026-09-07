[CmdletBinding()]
param(
    [string]$Region = "ap-south-2",

    [string]$ClusterName = "",

    [string]$Namespace = "paysecure",

    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Continue"

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {

    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    $OutputDirectory = Join-Path `
        "drill-evidence" `
        "evidence-$Timestamp"
}

New-Item `
    -ItemType Directory `
    -Path $OutputDirectory `
    -Force | Out-Null

Write-Host ""
Write-Host "=========================================="
Write-Host " PaySecure DR Evidence Collection"
Write-Host "=========================================="
Write-Host ""

Write-Host "Output:"
Write-Host $OutputDirectory

Write-Host ""
Write-Host "Collecting AWS identity..."

aws sts get-caller-identity `
    | Out-File "$OutputDirectory/aws-identity.json"

Write-Host "Collecting region information..."

aws ec2 describe-availability-zones `
    --region $Region `
    --output json `
    | Out-File "$OutputDirectory/availability-zones.json"

Write-Host "Collecting EKS..."

aws eks list-clusters `
    --region $Region `
    --output json `
    | Out-File "$OutputDirectory/eks.json"

Write-Host "Collecting Aurora..."

aws rds describe-global-clusters `
    --region $Region `
    --output json `
    | Out-File "$OutputDirectory/aurora.json"

Write-Host "Collecting DynamoDB..."

aws dynamodb list-tables `
    --region $Region `
    --output json `
    | Out-File "$OutputDirectory/dynamodb.json"

Write-Host "Collecting MSK..."

aws kafka list-clusters-v2 `
    --region $Region `
    --output json `
    | Out-File "$OutputDirectory/msk.json"

Write-Host "Collecting ElastiCache..."

aws elasticache describe-replication-groups `
    --region $Region `
    --output json `
    | Out-File "$OutputDirectory/elasticache.json"

Write-Host "Collecting Route 53..."

aws route53 list-health-checks `
    --output json `
    | Out-File "$OutputDirectory/route53-health-checks.json"

Write-Host "Collecting ALBs..."

aws elbv2 describe-load-balancers `
    --region $Region `
    --output json `
    | Out-File "$OutputDirectory/load-balancers.json"

if ($ClusterName) {

    Write-Host ""
    Write-Host "Collecting Kubernetes evidence..."

    aws eks update-kubeconfig `
        --region $Region `
        --name $ClusterName

    kubectl get nodes -o wide `
        | Out-File "$OutputDirectory/k8s-nodes.txt"

    kubectl get pods `
        --namespace $Namespace `
        -o wide `
        | Out-File "$OutputDirectory/k8s-pods.txt"

    kubectl get deployments `
        --namespace $Namespace `
        | Out-File "$OutputDirectory/k8s-deployments.txt"

    kubectl get services `
        --namespace $Namespace `
        | Out-File "$OutputDirectory/k8s-services.txt"

    kubectl get hpa `
        --namespace $Namespace `
        | Out-File "$OutputDirectory/k8s-hpa.txt"

    kubectl get pdb `
        --namespace $Namespace `
        | Out-File "$OutputDirectory/k8s-pdb.txt"
}

@"
Evidence Collection
==================

Collected: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
Region: $Region
Namespace: $Namespace

Files in this directory represent the infrastructure state
observed during the DR drill.

Required manual evidence:
- DNS resolution screenshots
- Test transaction IDs
- RTO measurement
- RPO measurement
- Monitoring screenshots
- Communication timestamps
- Approval/change records
"@ | Out-File "$OutputDirectory/README.txt"

Write-Host ""
Write-Host "Evidence collection complete."
Write-Host "Location: $OutputDirectory"