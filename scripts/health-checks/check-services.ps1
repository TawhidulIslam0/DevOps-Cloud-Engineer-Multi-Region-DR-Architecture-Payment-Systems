[CmdletBinding()]
param(
    [string]$Region = "ap-south-2",

    [string]$ClusterName = "",

    [string]$Namespace = "paysecure"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=========================================="
Write-Host " PaySecure Service Health Check"
Write-Host "=========================================="
Write-Host ""

Write-Host "Region:    $Region"
Write-Host "Namespace: $Namespace"
Write-Host ""

Write-Host "1. EKS clusters"

aws eks list-clusters `
    --region $Region `
    --output table

if ($ClusterName) {

    Write-Host ""
    Write-Host "2. Updating kubeconfig"

    aws eks update-kubeconfig `
        --region $Region `
        --name $ClusterName

    Write-Host ""
    Write-Host "3. Kubernetes nodes"

    kubectl get nodes -o wide

    Write-Host ""
    Write-Host "4. Pods"

    kubectl get pods `
        --namespace $Namespace `
        -o wide

    Write-Host ""
    Write-Host "5. Deployments"

    kubectl get deployments `
        --namespace $Namespace

    Write-Host ""
    Write-Host "6. Services"

    kubectl get services `
        --namespace $Namespace

    Write-Host ""
    Write-Host "7. HPA"

    kubectl get hpa `
        --namespace $Namespace

    Write-Host ""
    Write-Host "8. Pod disruption budgets"

    kubectl get pdb `
        --namespace $Namespace
}
else {
    Write-Host ""
    Write-Host "ClusterName not supplied."
    Write-Host "Kubernetes-specific checks skipped."
}

Write-Host ""
Write-Host "Service health check complete."