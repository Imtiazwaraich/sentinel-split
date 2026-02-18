# Helper script to get backend service internal IP for gateway configuration
# Usage: .\scripts\get-backend-ip.ps1

$ErrorActionPreference = "Stop"

$AWS_REGION = "us-west-2"
$CLUSTER_NAME = "eks-sentinel-v1-backend"

# Configure kubectl for backend cluster
Write-Host "Configuring kubectl for backend cluster..." -ForegroundColor Cyan
& aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION --alias $CLUSTER_NAME | Out-Null

# Get backend service endpoint
Write-Host "`nFetching backend service information..." -ForegroundColor Yellow
Write-Host ""

# Option 1: Pod IP (requires direct pod-to-pod communication)
$POD_IP = & kubectl --context $CLUSTER_NAME get pods -l app=backend -o jsonpath='{.items[0].status.podIP}'
Write-Host "Backend Pod IP: $POD_IP" -ForegroundColor Green

# Option 2: Service ClusterIP (internal to backend cluster)
$SERVICE_IP = & kubectl --context $CLUSTER_NAME get svc backend-service -o jsonpath='{.spec.clusterIP}'
Write-Host "Backend Service IP: $SERVICE_IP" -ForegroundColor Green

Write-Host "`nTo configure the gateway, update k8s/gateway/configmap.yaml:" -ForegroundColor White
Write-Host "  BACKEND_SERVICE_HOST: `"$SERVICE_IP`"" -ForegroundColor Cyan
Write-Host "  BACKEND_SERVICE_PORT: `"80`"" -ForegroundColor Cyan

Write-Host "`nNote: For production, consider using AWS Cloud Map or an internal NLB" -ForegroundColor DarkGray
