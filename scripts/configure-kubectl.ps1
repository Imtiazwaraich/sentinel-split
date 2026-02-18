# Helper script to configure kubectl for both EKS clusters
# Usage: .\scripts\configure-kubectl.ps1

$ErrorActionPreference = "Stop"

$AWS_REGION = "us-west-2"
$GATEWAY_CLUSTER = "eks-sentinel-v1-gateway"
$BACKEND_CLUSTER = "eks-sentinel-v1-backend"

Write-Host "Configuring kubectl for Gateway cluster..." -ForegroundColor Cyan
& aws eks update-kubeconfig `
    --name $GATEWAY_CLUSTER `
    --region $AWS_REGION `
    --alias $GATEWAY_CLUSTER

Write-Host "`nConfiguring kubectl for Backend cluster..." -ForegroundColor Cyan
& aws eks update-kubeconfig `
    --name $BACKEND_CLUSTER `
    --region $AWS_REGION `
    --alias $BACKEND_CLUSTER

Write-Host "`n✓ Successfully configured kubectl for both clusters" -ForegroundColor Green

Write-Host "`nAvailable contexts:" -ForegroundColor Yellow
& kubectl config get-contexts

Write-Host "`nTo switch contexts, use:" -ForegroundColor White
Write-Host "  kubectl config use-context $GATEWAY_CLUSTER" -ForegroundColor Cyan
Write-Host "  kubectl config use-context $BACKEND_CLUSTER" -ForegroundColor Cyan
